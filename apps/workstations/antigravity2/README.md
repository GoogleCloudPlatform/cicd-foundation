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

# Antigravity 2.0 Custom Image for Cloud Workstations

This image layers the **Antigravity 2.0** application onto the [GNOME Workstation Blueprint](../gnome/README.md).

## Overview

Antigravity 2.0 provides a next-generation development experience with advanced AI integration and optimized performance for cloud-native workflows.

## Configuration

The following build arguments can be used to customize the image:

| Argument              | Default | Description                            |
| :-------------------- | :------ | :------------------------------------- |
| `ANTIGRAVITY_VERSION` | `1.0.7` | The version of Antigravity to install. |

## Documentation

- 👉 **[AGENTS.md](./AGENTS.md)**: AI agent instructions for this layer.
- 👉 **[GNOME Foundation](../gnome/README.md)**: The underlying desktop environment.
