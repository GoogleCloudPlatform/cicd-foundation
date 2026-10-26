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

# node-demo

## Overview

Node.js and TypeScript Development Container demo application
(`devcontainer-node-demo` v1.0.0) for testing DevContainer compilation and
execution inside Cloud Workstations. It pairs a Skaffold custom build definition
(`skaffold.yaml`), DevContainer configuration
(`.devcontainer/devcontainer.json`), and TypeScript/NPM build manifests
(`package.json`, `tsconfig.json`) with an Express server in `src/`.

## Subdirectories & Boundaries

- `src`: [`./src/EGM.md`](./src/EGM.md) - TypeScript Express server entrypoint
  (`index.ts`) exposing `/` and `/health`.

## Interface

- `skaffold.yaml`: Skaffold configuration (`devcontainer-node-demo`,
  `apiVersion: skaffold/v3`) building artifact image
  `devcontainer-node-demo-image` via custom command `build_devcontainer
$IMAGE`.
- `package.json`: NPM package manifest (`devcontainer-node-demo` v1.0.0,
  `main: "dist/index.js"`) defining scripts `build` (`tsc`), `start` (`node
dist/index.js`), and `dev` (`ts-node src/index.ts`).
- `tsconfig.json`: TypeScript compiler configuration targeting `es2022` /
  `commonjs` with `rootDir: "./src"`, `outDir: "./dist"`, and `strict: true`.
- `.devcontainer/devcontainer.json`: DevContainer specification (`Node.js
DevContainer Demo`) based on
  `mcr.microsoft.com/devcontainers/typescript-node:22-bookworm`, configuring
  VS Code settings (`editor.formatOnSave: true`, `editor.defaultFormatter:
"esbenp.prettier-vscode"`) and extensions (`dbaeumer.vscode-eslint`,
  `esbenp.prettier-vscode`), forwarding port `3000`, and running `npm install`
  as `postCreateCommand`.
- [`./src/EGM.md`](./src/EGM.md): Express HTTP server implementation in
  `src/index.ts`.

## Invariants

- TypeScript sources under `./src` compile to `./dist` with strict
  type-checking enabled (`strict: true`).
- Skaffold custom build requires `build_devcontainer` to be available on
  `PATH`.

## Side Effects

- Running `skaffold build` invokes `build_devcontainer $IMAGE` to build and
  push `devcontainer-node-demo-image`.
- Container creation executes `npm install` via `postCreateCommand` and
  forwards TCP port `3000`.
