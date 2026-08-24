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

# Base OS orchestration layer

This module provides the central orchestration for all workstation images. It provides Systemd mechanisms, logging, environmental injection triggers (Chezmoi), and development tool download hooks (Antigravity CLI, Agent Development Kit, Devcontainers CLI, gVisor). 

This module outputs an asset provider (`COPY --from=base-provider /export /`), meaning downstream runtime layers simply inherit configurations rather than duplicating setup logic.
