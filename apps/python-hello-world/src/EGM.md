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

Source container directory for the `python-hello-world` application, housing the
`python-hello-world` Flask container module.

## Subdirectories & Boundaries

- `python-hello-world`:
  [`./python-hello-world/EGM.md`](./python-hello-world/EGM.md) - Python Flask
  container module (`hello-world` v0.1.0) with `Procfile`, `pyproject.toml`,
  and `hello_world` package.

## Interface

- [`./python-hello-world/EGM.md`](./python-hello-world/EGM.md): Exposes
  `Procfile`, `pyproject.toml`, and `hello_world.app` (`GET /`, `NAME`).

## Invariants

- Follows the repository convention `/apps/${APP_NAME}/src/${CONTAINER_NAME}/`
  where `${CONTAINER_NAME}` matches `python-hello-world`.

## Side Effects

- Delegates Flask HTTP server startup on port `8080` to
  [`./python-hello-world/EGM.md`](./python-hello-world/EGM.md).
