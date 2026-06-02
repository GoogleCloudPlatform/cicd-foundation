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

# Antigravity Software Bill of Materials (SBOM)

This document tracks the primary open-source and proprietary components bundled within the **Antigravity Custom Image for Cloud Workstations**.

## Core Antigravity Components

| Component                       | License            | Description                                                  |
| :------------------------------ | :----------------- | :----------------------------------------------------------- |
| **antigravity**                 | Proprietary/Custom | The core desktop shell and dashboard provided by this image. |
| **Gemini CLI**                  | Apache 2.0         | AI-powered terminal assistant and automation tool.           |
| **Agent Development Kit (ADK)** | Apache 2.0         | Python libraries for AI agent orchestration.                 |

## Third-Party Dependencies (Layered)

These components are inherited from the [GNOME Layer](../../gnome/docs/software_bill_of_materials.md) but are essential for Antigravity's operation.

| Component                | License    | Role                    |
| :----------------------- | :--------- | :---------------------- |
| **GNOME Shell 46**       | GPL-2.0+   | Graphical environment.  |
| **Apache Guacamole**     | Apache 2.0 | Remote desktop gateway. |
| **Ubuntu 24.04 (Noble)** | Various    | Base Operating System.  |

## Repository Sources

Antigravity pulls packages from the following authorized sources during the build process:

1.  **Ubuntu Universe/Main**: Standard OS packages.
2.  **Google Cloud Artifact Registry**: Private repositories for `antigravity` and specialized SDKs.
3.  **PyPI**: Python dependencies for the Agent Development Kit.

---

Brought to you by the Google Cloud Professional Services Organization Apps team (PSO AppΣ)
