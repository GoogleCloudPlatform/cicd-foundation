<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Guacamole Audio Bridge (`guacamole-audio-bridge`)

## Overview

Apache Guacamole 1.6.0 extension (`guac-audio-bridge` / `WebAudio Streaming
Bridge`) that streams bidirectional raw 16-bit PCM audio between the browser
WebAudio API and a `/audio/ws` WebSocket endpoint.

## Interface

- `guac-manifest.json`: Declares Guacamole 1.6.0 extension namespace
  `guac-audio-bridge`, name `WebAudio Streaming Bridge`, and script entry
  point `audio-bridge.js`.
- `audio-bridge.js`: Self-invoking anonymous function (IIFE) with no exported
  global symbols; integrates via DOM `window`/`document` events, WebAudio API,
  MediaDevices API, and WebSocket endpoint `/audio/ws` (template variable
  `${DEFAULT_ENABLE_AUDIO_INPUT}` controls microphone capture).

## Invariants

- Audio sample rate is fixed at 44100 Hz (`SAMPLE_RATE = 44100`).
- Playback audio uses 2 interleaved channels (`CHANNELS = 2`) of signed 16-bit
  PCM normalized by dividing by `32768.0`, with a 20ms (`0.02`s) minimum
  jitter buffer ahead of `audioCtx.currentTime`.
- Microphone input capture only activates when `${DEFAULT_ENABLE_AUDIO_INPUT}`
  evaluates to `'true'`, using a mono (1 input, 1 output channel)
  `ScriptProcessorNode` with buffer size `4096` and clamping float samples to
  `[-1, 1]` before scaling to 16-bit signed integers (`0x8000` for negative,
  `0x7fff` for positive).
- At most one active or connecting WebSocket instance (`ws`) and one
  `AudioContext` instance (`audioCtx`) exist per page lifecycle.
- WebSocket URL protocol is `wss:` when `window.location.protocol` is
  `'https:'`, otherwise `ws:`, targeting
  `${proto}//${window.location.host}/audio/ws` with `binaryType =
'arraybuffer'`.

## Side Effects

- Registers one-time `window` event listeners for `click`, `keydown`, and
  `touchstart` to unlock/resume `AudioContext`, initiate WebSocket connection,
  and optionally start microphone capture.
- Registers a `load` event listener on `window` (or immediately connects if
  `document.readyState` is `'complete'`) to open the WebSocket connection to
  `/audio/ws`.
- Opens a persistent WebSocket connection to `/audio/ws` that automatically
  schedules reconnection via `setTimeout` after 3000ms upon closure and closes
  itself upon error.
- Creates and resumes a browser `AudioContext` (or `webkitAudioContext`) and
  plays incoming `ArrayBuffer` PCM chunks through `audioCtx.destination`.
- Requests user microphone permissions via
  `navigator.mediaDevices.getUserMedia({ audio: { echoCancellation: true,
noiseSuppression: true } })` when audio input is enabled and streams
  captured 16-bit PCM buffers over the open WebSocket.
