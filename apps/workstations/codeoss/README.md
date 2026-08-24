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

# CodeOSS Workstation Image

This module provides a headless CodeOSS IDE environment that is fully compliant with the Google Cloud Workstations structural blueprint. It imports all mechanics built by the `base` asset provider (including the Nginx preflight loader), automatically triggering the installation of the Devcontainers CLI and gVisor via environmental flags inherited into the workspace installation runtime.
