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

# Antigravity Layer Documentation

This directory contains technical documentation for the **Antigravity Custom Image for Cloud Workstations**, which builds upon the GNOME desktop foundation to provide a specialized development environment.

## Documentation Standards

To ensure consistency and compatibility across the project, adhere to the following standards:

### File Naming

- **Convention**: Use `snake_case.md` for all technical documentation (e.g., `design.md`).
- **Rationale**: Ensures maximum compatibility with Linux environments, web servers, and consistent sorting in IDEs.
- **Exception**: Root-level files like `README.md` or `LICENSE` remain in UPPERCASE as per industry standard.

### Structure & Redundancy

- **Agnosticism**: Documentation in this directory should focus exclusively on the Antigravity-specific tools, customizations, and the layering mechanism.
- **Linking**: Avoid duplicating information from the base GNOME layer. Refer to the [GNOME Layer Documentation](../../gnome/docs/README.md) for details on the underlying OS and remote access stack.

### README Strategy

- **Top-Level `README.md`**: Reserved for external consumption. Must contain a high-level overview, configuration variables (ARGs/ENVs), and a link pointing developers to the `docs/` folder.
- **Internal `docs/README.md`**: Reserved for internal maintenance. Acts as the table of contents for technical deep-dives (`design.md`, `software_bill_of_materials.md`, etc.).

## Documentation Map

| File                                                           | Purpose                                                               |
| :------------------------------------------------------------- | :-------------------------------------------------------------------- |
| [design.md](design.md)                                         | Antigravity-specific layering and build-time integration logic.       |
| [requirements.md](requirements.md)                             | Functional and non-functional requirements for the Antigravity layer. |
| [software_bill_of_materials.md](software_bill_of_materials.md) | Tracking of bundled Antigravity components and licenses.              |
| [GNOME Design](../../gnome/docs/design.md)                     | Deep-dive into the underlying graphical session and remote protocols. |

---

Brought to you by the Google Cloud Professional Services Organization Apps team (PSO AppΣ)
