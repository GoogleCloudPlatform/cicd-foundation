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

# src

## Overview

TypeScript source directory (`index.ts`) for the Node.js Development Container
demo application (`devcontainer-node-demo`), defining and starting an Express
HTTP server with root runtime metadata and health check endpoints.

## Interface

- `index.ts`: Executable TypeScript entry module starting an Express HTTP
  server.
- `GET /`: HTTP endpoint returning JSON with `message` (`"Hello from the
Node.js DevContainer Demo!"`), `status` (`"healthy"`), ISO-8601 `timestamp`,
  and `environment` (`nodeVersion`, `platform`, `arch`).
- `GET /health`: HTTP health check endpoint returning JSON `{"status": "UP"}`.
- `PORT`: Optional environment variable configuring the server listening port
  (defaults to `3000`).

## Invariants

- Registers `express.json()` middleware globally before route handlers.
- Falls back to TCP port `3000` when `process.env.PORT` is unset or falsy.
- `GET /` static fields `message` and `status` are always `"Hello from the
Node.js DevContainer Demo!"` and `"healthy"`.
- `GET /health` always returns `{"status": "UP"}`.

## Side Effects

- Reads `process.env.PORT`, `process.version`, `process.platform`, and
  `process.arch` from the Node.js process environment.
- Starts an HTTP server listening on `port` (`process.env.PORT || 3000`)
  immediately upon module load.
- Writes startup log `Server is running on http://localhost:${port}` to stdout
  via `console.log`.
