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

# java

## Overview

Java source root (`src/main/java`) for the `java-hello-world` Spring Boot
application, housing the `hello` package.

## Subdirectories & Boundaries

- `hello`: [`./hello/EGM.md`](./hello/EGM.md) - Spring Boot application entry
  point (`Application`) and REST greeting controller (`HelloController`).

## Interface

- [`./hello/EGM.md`](./hello/EGM.md): Exposes `hello.Application`,
  `hello.Application.main(String[] args)`, `hello.HelloController`, and
  `hello.HelloController.index()`.

## Invariants

- Organizes Java sources under the standard Maven `src/main/java` source root.

## Side Effects

- Propagates Spring Boot startup and HTTP server binding side effects from
  [`./hello/EGM.md`](./hello/EGM.md).
