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

Source container directory for the `node-hello-world` application, housing the
`node-hello-world` Express container module.

## Subdirectories & Boundaries

- `node-hello-world`:
  [`./node-hello-world/EGM.md`](./node-hello-world/EGM.md) - Node.js Express
  web application serving `GET /` and static assets from `public/`.

## Interface

- [`./node-hello-world/EGM.md`](./node-hello-world/EGM.md): Exposes `index.js`
  (`GET /`, static `public/hello.html`, and environment variable `NAME`).

## Invariants

- Follows the repository convention `/apps/${APP_NAME}/src/${CONTAINER_NAME}/`
  where `${CONTAINER_NAME}` matches `node-hello-world`.

## Side Effects

- Delegates HTTP server binding on port `8080` and static file serving to
  [`./node-hello-world/EGM.md`](./node-hello-world/EGM.md).
