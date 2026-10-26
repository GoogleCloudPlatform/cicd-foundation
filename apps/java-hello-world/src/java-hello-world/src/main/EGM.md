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

# main

## Overview

Maven `src/main` directory for the `java-hello-world` Spring Boot project,
containing production Java source code under `java/`.

## Subdirectories & Boundaries

- `java`: [`./java/EGM.md`](./java/EGM.md) - Java source root containing the
  `hello` Spring Boot package.

## Interface

- [`./java/EGM.md`](./java/EGM.md): Exposes the `hello` package
  (`Application`, `HelloController`).

## Invariants

- Follows the standard Maven directory layout (`src/main/java`).

## Side Effects

- Delegates application execution to [`./java/EGM.md`](./java/EGM.md).
