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

Maven source tree (`src/`) for the `java-hello-world` container module,
containing production sources under `main/`.

## Subdirectories & Boundaries

- `main`: [`./main/EGM.md`](./main/EGM.md) - Production Maven source tree
  (`src/main/java/hello`).

## Interface

- [`./main/EGM.md`](./main/EGM.md): Exposes the `hello` Spring Boot package.

## Invariants

- Adheres to standard Maven source hierarchy conventions consumed by
  `pom.xml`.

## Side Effects

- Delegates runtime HTTP server behavior to [`./main/EGM.md`](./main/EGM.md).
