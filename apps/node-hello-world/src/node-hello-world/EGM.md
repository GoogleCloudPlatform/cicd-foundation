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

# node-hello-world

## Overview

Node.js Express web application (`node-hello-world` v1.0.0) that serves static
assets from the `public/` directory (`hello.html`) and responds to HTTP `GET /`
requests with a greeting parameterized by the `NAME` environment variable.

## Interface

- `index.js`: Main Express application entrypoint (`npm start` runs `node
index.js`).
- `GET /`: HTTP route handler responding with `'Hello <NAME> from NodeJS!'`.
- `public/`: Static asset directory served via `express.static('public')`
  (including `GET /hello.html`).
- `NAME`: Optional environment variable customizing the greeting target
  (defaults to `'World'`).

## Invariants

- Server listening port is hardcoded to TCP port `8080`.
- Greeting target name defaults to `'World'` when `process.env.NAME` is unset
  or falsy.
- Requires `express` (`^4.22.3`) as declared in `package.json`.

## Side Effects

- Reads `process.env.NAME` at module initialization.
- Binds an HTTP server to TCP port `8080` immediately when `index.js` is
  executed.
- Serves static files from the `public` directory relative to the process
  working directory.
- Writes `'Listening on Port 8080.'` to stdout via `console.log` on server
  startup.
