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

# java-hello-world

## Overview

Maven-managed Spring Boot container module (`org.skaffold:hello-spring-boot`
v0.1.0, Java 17) for the `java-hello-world` application. It defines the Maven
build configuration (`pom.xml` with `spring-boot-maven-plugin` and
`jib-maven-plugin`) and houses the Java source tree under `src/`.

## Subdirectories & Boundaries

- `src`: [`./src/EGM.md`](./src/EGM.md) - Maven source tree
  (`src/main/java/hello`) containing `Application` and `HelloController`.

## Interface

- `pom.xml`: Maven project descriptor (`groupId: org.skaffold`, `artifactId:
hello-spring-boot`, `version: 0.1.0`, parent
  `org.springframework.boot:spring-boot-starter-parent:2.7.4`, dependency
  `spring-boot-starter-web`, final artifact name `hello`).
- [`./src/EGM.md`](./src/EGM.md): Exposes `hello.Application` and
  `hello.HelloController` (`GET /`, `NAME`).

## Invariants

- Targets Java version `17` (`<java.version>17</java.version>`) and pins
  `org.yaml:snakeyaml` to version `2.0`.
- Configures `jib-maven-plugin` (`3.4.1`) with base image `openjdk:17` and JVM
  flag `-Djava.security.egd=file:/dev/./urandom`.

## Side Effects

- Building via Maven or Google Cloud Buildpacks resolves dependencies from
  Maven repositories, compiles Java sources under `src/`, and packages the
  `hello` Spring Boot executable archive.
