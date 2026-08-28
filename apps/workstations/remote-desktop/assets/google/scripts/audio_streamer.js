#!/usr/bin/env node

/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

const http = require('node:http');
const crypto = require('node:crypto');
const { spawn } = require('node:child_process');

const PORT = parseInt(process.env.AUDIO_STREAMER_PORT || '8081', 10);
const SAMPLE_RATE = 44100;
const CHANNELS = 2;

const clients = new Set();
let recorderProcess = null;
let restartTimer = null;

function broadcastFrame(buffer) {
  if (clients.size === 0) return;
  const frame = encodeWebSocketFrame(buffer, 0x02); // 0x02 = Binary frame
  for (const socket of clients) {
    if (socket.writable && !socket.destroyed) {
      socket.write(frame);
    }
  }
}

function startRecorder() {
  if (recorderProcess) return;

  const targetUid = process.getuid ? process.getuid() : 1000;
  const pulseServer = process.env.PULSE_SERVER || `unix:/run/user/${targetUid}/pulse/native`;
  const env = {
    ...process.env,
    PULSE_SERVER: pulseServer,
    XDG_RUNTIME_DIR: `/run/user/${targetUid}`,
  };

  // Capture monitor stream using parec (standard in pulseaudio-utils / pipewire-pulse)
  // or pw-record
  const cmd = 'parec';
  const args = [
    '--format=s16le',
    `--rate=${SAMPLE_RATE}`,
    `--channels=${CHANNELS}`,
    '--latency-msec=20',
  ];

  try {
    recorderProcess = spawn(cmd, args, { env, stdio: ['ignore', 'pipe', 'ignore'] });

    recorderProcess.stdout.on('data', (chunk) => {
      broadcastFrame(chunk);
    });

    recorderProcess.on('exit', () => {
      recorderProcess = null;
      if (clients.size > 0 && !restartTimer) {
        restartTimer = setTimeout(() => {
          restartTimer = null;
          startRecorder();
        }, 1000);
      }
    });

    recorderProcess.on('error', () => {
      recorderProcess = null;
      if (clients.size > 0 && !restartTimer) {
        restartTimer = setTimeout(() => {
          restartTimer = null;
          startRecorder();
        }, 2000);
      }
    });
  } catch {
    recorderProcess = null;
  }
}

function stopRecorderIfIdle() {
  if (clients.size === 0 && recorderProcess) {
    recorderProcess.kill('SIGTERM');
    recorderProcess = null;
  }
}

function encodeWebSocketFrame(payload, opcode = 0x02) {
  const length = payload.length;
  let header;

  if (length < 126) {
    header = Buffer.alloc(2);
    header[0] = 0x80 | opcode; // FIN + opcode
    header[1] = length; // Unmasked
  } else if (length < 65536) {
    header = Buffer.alloc(4);
    header[0] = 0x80 | opcode;
    header[1] = 126;
    header.writeUInt16BE(length, 2);
  } else {
    header = Buffer.alloc(10);
    header[0] = 0x80 | opcode;
    header[1] = 127;
    header.writeBigUInt64BE(BigInt(length), 2);
  }

  return Buffer.concat([header, payload]);
}

function parseWebSocketFrames(buffer, onMessage) {
  let offset = 0;
  while (offset + 2 <= buffer.length) {
    const firstByte = buffer[offset];
    const secondByte = buffer[offset + 1];
    const opcode = firstByte & 0x0f;
    const isMasked = (secondByte & 0x80) !== 0;
    let payloadLength = secondByte & 0x7f;
    let headerSize = 2;

    if (payloadLength === 126) {
      if (offset + 4 > buffer.length) break;
      payloadLength = buffer.readUInt16BE(offset + 2);
      headerSize = 4;
    } else if (payloadLength === 127) {
      if (offset + 10 > buffer.length) break;
      payloadLength = Number(buffer.readBigUInt64BE(offset + 2));
      headerSize = 10;
    }

    const maskSize = isMasked ? 4 : 0;
    const totalFrameSize = headerSize + maskSize + payloadLength;
    if (offset + totalFrameSize > buffer.length) break;

    let payload = buffer.subarray(offset + headerSize + maskSize, offset + totalFrameSize);

    if (isMasked) {
      const maskKey = buffer.subarray(offset + headerSize, offset + headerSize + 4);
      const unmasked = Buffer.alloc(payloadLength);
      for (let i = 0; i < payloadLength; i++) {
        unmasked[i] = payload[i] ^ maskKey[i % 4];
      }
      payload = unmasked;
    }

    onMessage(opcode, payload);
    offset += totalFrameSize;
  }

  return buffer.subarray(offset);
}

const server = http.createServer((req, res) => {
  if (req.url === '/livez' || req.url === '/healthz' || req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('OK');
    return;
  }
  res.writeHead(404);
  res.end();
});

server.on('upgrade', (req, socket) => {
  const acceptKey = req.headers['sec-websocket-key'];
  if (!acceptKey) {
    socket.destroy();
    return;
  }

  const hash = crypto
    .createHash('sha1')
    .update(acceptKey + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')
    .digest('base64');

  socket.write(
    'HTTP/1.1 101 Switching Protocols\r\n' +
    'Upgrade: websocket\r\n' +
    'Connection: Upgrade\r\n' +
    `Sec-WebSocket-Accept: ${hash}\r\n` +
    '\r\n'
  );

  clients.add(socket);
  startRecorder();

  // Microphone player process for this client
  let micPlayer = null;
  const targetUid = process.getuid ? process.getuid() : 1000;
  const env = {
    ...process.env,
    PULSE_SERVER: process.env.PULSE_SERVER || `unix:/run/user/${targetUid}/pulse/native`,
    XDG_RUNTIME_DIR: `/run/user/${targetUid}`,
  };

  try {
    micPlayer = spawn('pacat', ['--playback', '--format=s16le', '--rate=44100', '--channels=1'], {
      env,
      stdio: ['pipe', 'ignore', 'ignore'],
    });
    micPlayer.on('error', () => {
      micPlayer = null;
    });
  } catch {
    micPlayer = null;
  }

  let incomingBuffer = Buffer.alloc(0);

  socket.on('data', (chunk) => {
    incomingBuffer = Buffer.concat([incomingBuffer, chunk]);
    incomingBuffer = parseWebSocketFrames(incomingBuffer, (opcode, payload) => {
      if (opcode === 0x08) {
        // Close frame
        socket.end(encodeWebSocketFrame(Buffer.alloc(0), 0x08));
        socket.destroy();
      } else if (opcode === 0x09) {
        // Ping -> Pong
        socket.write(encodeWebSocketFrame(payload, 0x0a));
      } else if (opcode === 0x02 && micPlayer && micPlayer.stdin.writable) {
        // Binary audio chunk from microphone
        micPlayer.stdin.write(payload);
      }
    });
  });

  const cleanup = () => {
    clients.delete(socket);
    if (micPlayer) {
      try {
        micPlayer.stdin.end();
        micPlayer.kill('SIGTERM');
      } catch {
        // Process may already be dead
      }
      micPlayer = null;
    }
    stopRecorderIfIdle();
  };

  socket.on('close', cleanup);
  socket.on('error', cleanup);
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Low-Latency Audio Streamer listening on 127.0.0.1:${PORT}`);
});
