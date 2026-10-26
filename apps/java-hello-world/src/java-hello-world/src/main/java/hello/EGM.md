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

# hello

## Overview

Spring Boot web application package (`hello`) containing the main application
entry point (`Application`) and a REST controller (`HelloController`) that
serves a greeting message on the root HTTP endpoint (`/`).

## Interface

- `hello.Application`: `@SpringBootApplication` entry point class.
- `hello.Application.main(String[] args)`: Static entry method launching the
  Spring Boot application.
- `hello.HelloController`: `@RestController` handling HTTP requests for the
  root path.
- `hello.HelloController.index()`: `@RequestMapping("/")` handler returning
  `"Hello <name> from Java!"`.
- `NAME`: Optional configuration property or environment variable
  (`@Value("${NAME:World}")`) customizing the greeting target.

## Invariants

- `HelloController.name` defaults to `"World"` if the `NAME` property or
  environment variable is not provided (`@Value("${NAME:World}")`).
- Requests to `"/"` handled by `HelloController.index()` always return a
  string formatted as `"Hello <name> from Java!"`.

## Side Effects

- `Application.main(String[] args)` boots the Spring application context and
  starts an embedded HTTP server via `SpringApplication.run(Application.class,
args)`.
- Spring resolves the `${NAME:World}` property from the environment or
  application properties during `HelloController` bean instantiation.
