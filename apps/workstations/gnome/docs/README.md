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

# GNOME Layer Documentation

This directory contains technical documentation for the **GNOME Application Layer** of the Cloud Workstation blueprint.

## Documentation Standards

To ensure consistency and compatibility across the project, adhere to the following standards:

### File Naming

- **Convention**: Use `snake_case.md` for all technical documentation (e.g., `design.md`).
- **Rationale**: Ensures maximum compatibility with Linux environments, web servers, and consistent sorting in IDEs.
- **Exception**: Root-level files like `README.md` or `LICENSE` remain in UPPERCASE as per industry standard.

### Structure & Redundancy

- **Agnosticism**: Documentation in this directory should focus exclusively on the GNOME desktop environment, systemd orchestration, and RDP/Wayland configuration.
- **Linking**: Avoid duplicating information from base layers. Instead, refer to the documentation of parent or sibling layers where appropriate.

### README Strategy

- **Top-Level `README.md`**: Reserved for external consumption. Must contain a high-level overview, configuration variables (ARGs/ENVs), quick-start guides, and a link pointing developers to the `docs/` folder.
- **Internal `docs/README.md`**: Reserved for internal maintenance. Acts as the table of contents for technical deep-dives (`design.md`, `requirements.md`, etc.) and enforces layer-specific documentation rules.

## Documentation Map

| File                                                           | Purpose                                                           |
| :------------------------------------------------------------- | :---------------------------------------------------------------- |
| [design.md](design.md)                                         | Core architecture, Systemd orchestration, and developer patterns. |
| [requirements.md](requirements.md)                             | Functional and non-functional requirements for the GNOME layer.   |
| [deployment_guide.md](../../docs/deployment_guide.md)          | Infrastructure and build pipeline details.                        |
| [ux_standards.md](../../preflight/docs/ux_standards.md)        | Accessibility and design language for the desktop.                |
| [software_bill_of_materials.md](software_bill_of_materials.md) | Tracking of bundled OSS components and licenses.                  |
| [environment_variables.md](environment_variables.md)           | Runtime and build-time configuration reference.                   |
| [style_guides/](../../../../docs/style_guides/)                | Language-specific coding and configuration standards.             |

---

Brought to you by the Google Cloud Professional Services Organization Apps team (PSO AppΣ)
