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

(function () {
  "use strict";

  const SAMPLE_RATE = 44100;
  const CHANNELS = 2;
  const ENABLE_AUDIO_INPUT = "${DEFAULT_ENABLE_AUDIO_INPUT}" === "true";

  let audioCtx = null;
  let ws = null;
  let nextStartTime = 0;
  let micStream = null;
  let micProcessor = null;

  function initAudioContext() {
    if (!audioCtx) {
      const AudioContextClass =
        window.AudioContext || window.webkitAudioContext;
      if (AudioContextClass) {
        audioCtx = new AudioContextClass({ sampleRate: SAMPLE_RATE });
      }
    }
    if (audioCtx && audioCtx.state === "suspended") {
      audioCtx.resume();
    }
  }

  function playPcmChunk(arrayBuffer) {
    if (!audioCtx) return;

    const int16Array = new Int16Array(arrayBuffer);
    const frameCount = int16Array.length / CHANNELS;
    if (frameCount <= 0) return;

    const audioBuffer = audioCtx.createBuffer(
      CHANNELS,
      frameCount,
      SAMPLE_RATE,
    );
    const leftChannel = audioBuffer.getChannelData(0);
    const rightChannel = audioBuffer.getChannelData(1);

    for (let i = 0; i < frameCount; i++) {
      leftChannel[i] = int16Array[i * 2] / 32768.0;
      rightChannel[i] = int16Array[i * 2 + 1] / 32768.0;
    }

    const source = audioCtx.createBufferSource();
    source.buffer = audioBuffer;
    source.connect(audioCtx.destination);

    const currentTime = audioCtx.currentTime;
    if (nextStartTime < currentTime) {
      nextStartTime = currentTime + 0.02; // 20ms jitter buffer
    }

    source.start(nextStartTime);
    nextStartTime += audioBuffer.duration;
  }

  function startMicrophoneCapture() {
    if (!ENABLE_AUDIO_INPUT) {
      return;
    }

    if (
      micStream ||
      !navigator.mediaDevices ||
      !navigator.mediaDevices.getUserMedia
    ) {
      return;
    }

    navigator.mediaDevices
      .getUserMedia({
        audio: { echoCancellation: true, noiseSuppression: true },
      })
      .then((stream) => {
        micStream = stream;
        initAudioContext();
        if (!audioCtx) return;

        const micSource = audioCtx.createMediaStreamSource(stream);
        // 4096 buffer size ~= 92ms buffer at 44.1kHz
        const bufferSize = 4096;
        micProcessor = (
          audioCtx.createScriptProcessor || audioCtx.createJavaScriptNode
        ).call(audioCtx, bufferSize, 1, 1);

        micProcessor.onaudioprocess = (e) => {
          if (!ws || ws.readyState !== WebSocket.OPEN) return;
          const inputData = e.inputBuffer.getChannelData(0);
          const pcm16 = new Int16Array(inputData.length);
          for (let i = 0; i < inputData.length; i++) {
            const s = Math.max(-1, Math.min(1, inputData[i]));
            pcm16[i] = s < 0 ? s * 0x8000 : s * 0x7fff;
          }
          ws.send(pcm16.buffer);
        };

        micSource.connect(micProcessor);
        micProcessor.connect(audioCtx.destination);
      })
      .catch(() => {
        // User denied mic permission or no mic found
      });
  }

  function connectAudioStreamer() {
    if (
      ws &&
      (ws.readyState === WebSocket.OPEN ||
        ws.readyState === WebSocket.CONNECTING)
    ) {
      return;
    }

    const proto = window.location.protocol === "https:" ? "wss:" : "ws:";
    const host = window.location.host;
    const wsUrl = `${proto}//${host}/audio/ws`;

    ws = new WebSocket(wsUrl);
    ws.binaryType = "arraybuffer";

    ws.onopen = () => {
      initAudioContext();
    };

    ws.onmessage = (event) => {
      if (event.data instanceof ArrayBuffer) {
        initAudioContext();
        playPcmChunk(event.data);
      }
    };

    ws.onclose = () => {
      ws = null;
      // Reconnect after 3 seconds
      setTimeout(connectAudioStreamer, 3000);
    };

    ws.onerror = () => {
      if (ws) ws.close();
    };
  }

  // Unlock AudioContext on first user interaction in Guacamole
  function onUserGesture() {
    initAudioContext();
    connectAudioStreamer();
    if (ENABLE_AUDIO_INPUT) {
      startMicrophoneCapture();
    }
  }

  window.addEventListener("click", onUserGesture, { once: true });
  window.addEventListener("keydown", onUserGesture, { once: true });
  window.addEventListener("touchstart", onUserGesture, { once: true });

  // Auto-connect after page load
  if (document.readyState === "complete") {
    connectAudioStreamer();
  } else {
    window.addEventListener("load", connectAudioStreamer);
  }
})();
