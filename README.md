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

# Google Cloud CI/CD Foundation & Secure Developer Workstations

This repository provides a secure, audit-compliant CI/CD foundation and custom Cloud Workstation blueprints optimized for both human engineers and autonomous AI coding agents. It enables a modern **Agentic Software Development Lifecycle (SDLC)** by providing secure, pre-configured development environments with integrated AI toolchains.

---

## 1. Enterprise Architecture & Compliance

The repository is built to meet strict corporate compliance and security requirements out-of-the-box:

- **VPC Service Controls (VPC-SC)**: Fully compatible with VPC-SC service perimeters to prevent data exfiltration.
- **Shared VPC Networking**: Supports provisioning workstations and CI/CD pipelines in Shared VPC host/service project topologies.
- **Binary Authorization**: Enforces cryptographic signature validation on all containerized workloads deployed to runtimes (via Kritis integration).
- **Private Google Access & Private IP Workstations**: Workstations are isolated in private subnets with no public IP entry points, communicating securely over private gateways.
- **Secret Manager Encryption**: Secrets are stored securely in GCP Secret Manager and dynamically mapped to triggers at build-time.

---

## 2. Repository Map

```
├── apps/                          <-- Application Templates, DevContainers & Workstation Layers
│   ├── devcontainers/             <-- Standalone DevContainers for developer use
│   │   ├── gvisor-antigravity/    <-- gVisor + Antigravity devcontainer
│   │   ├── intellij/              <-- IntelliJ Ultimate devcontainer (with Antigravity CLI & SDK)
│   │   └── node-demo/             <-- Node.js DevContainer demo application
│   ├── workstations/              <-- Custom Google Cloud Workstation container layers
│   │   ├── android-studio-for-... <-- Android Studio for Platform (ASfP) workstation profile
│   │   ├── codeoss/               <-- Code OSS base workstation layer
│   │   ├── codeoss-devcontainer-intellij/ <-- Code OSS workstation with embedded IntelliJ devcontainer
│   │   ├── codeoss-devcontainer-gvisor-terraform/ <-- Code OSS workstation with gVisor and Terraform
│   │   ├── common/                <-- Central foundation workstation scripts & utilities
│   │   ├── gnome/                 <-- Secure, graphical headless RDP/Wayland GNOME workstation
│   │   ├── preflight/             <-- Preflight gateway daemon (controls desktop traffic)
│   │   ├── preflight-web/         <-- Preflight frontend status dashboard (Nginx & TypeScript)
│   │   └── remote-desktop/        <-- Apache Guacamole clientless browser remote desktop
│   ├── build-runner/              <-- Custom CI runner image supporting devcontainer.json builds
│   ├── go-hello-world/            <-- Go demo application template
│   ├── java-hello-world/          <-- Java demo application template
│   ├── node-hello-world/          <-- Node.js demo application template
│   └── python-hello-world/        <-- Python demo application template
│
├── docs/                          <-- System documentation and user guides
│
├── exercises/                     <-- Hands-on enablement exercises for developers and AI agents
│
├── infra/                         <-- Infrastructure-as-Code (Terraform)
│   ├── blueprints/
│   │   └── workstations/          <-- Provisioning of Cloud Workstations clusters and configurations
│   ├── modules/
│   │   ├── cicd_foundation/       <-- Foundation setup (networks, repos, governance)
│   │   ├── cicd_pipelines/        <-- Provisions Cloud Build triggers, Cloud Deploy, and BinAuth policies
│   │   └── cicd_workstations/     <-- Workstations integrations
│   └── simplified/                <-- Sandbox Terraform configuration for simplified single-project tests
│
├── presentations/                 <-- Enablement and presentation materials
│   └── md2tty/                    <-- Terminal & Browser markdown slideshow tool (TypeScript & Bash)
│
├── skills/                        <-- AI Agent personas, validation scripts, and Bat tests
└── tools/                         <-- Local developer utilities and Kritis policy definitions
```

---

## 3. Agentic SDLC & AI Developer Tooling

This repository is optimized to support collaborative pair-programming between human developers and autonomous AI agents (e.g., Jetski, Owl, etc.):

- **Integrated AI CLI (Antigravity)**: Custom workstations come pre-configured with the **Antigravity CLI** (`agy`), exposing context-aware terminal commands to assist with coding and execution.
- **Modular Agent Personas (`skills/`)**: Contains executable instruction specifications (`SKILL.md`) that guide AI behavior and enforce strict standards across SWE, SRE, Security, Privacy, and Licensing domains.
- **Automated Validation Lifecycle**: Enforces a strict 6-step testing workflow (from local unit/ Bats validation to live workstation integration testing) to verify that AI-generated changes do not cause drift or regression.

---

## 4. Hands-On Enablement & Exercises

The **`exercises/`** directory contains guided tasks designed to onboard both human developers and AI agents to the repository. These tasks cover:

- Onboarding application templates to the CI/CD pipeline.
- Defining custom workstation layers using Docker and shell hooks.
- Managing build environment variables and parsing GCP secrets using `sm://` syntax.
- Testing builds and auditing code compliance.

---

## 5. Presentation Utilities (`md2tty`)

The **`presentations/md2tty/`** folder contains a dual-mode markdown slideshow utility. It allows developers to run slideshows utilizing the **exact same markdown slides** (`presentations/md2tty/slides/`) in two ways:

- **`md2tty.sh` (Terminal-based)**: Renders slides directly inside a standard TTY shell using custom ANSI color escapes. Useful for quick terminal-based walkthroughs.
- **`md2tty.js` (Browser-based)**: Starts a local Vite dev server and renders slides as an interactive HTML deck in a web browser.

---

## 6. Google Cloud Professional Services (PSO) & Enablement

This repository contains open-source code, documentation, and enablement resources created by the **Google Cloud Professional Services Organization (PSO) AI Apps team**.

### Customer Engagements

If you want to establish or strengthen your organization's Agentic SDLC and CI/CD capabilities, you can partner with Google Cloud Professional Services:

- **How to Engage**: Reach out to your Google Cloud Representative, your [Technical Account Manager (TAM)](https://cloud.google.com/tam), or a certified [Google Cloud Partner](https://cloud.google.com/partners) to discuss structured enablement workshops.
- **Guided Enablement**: The hands-on modules in `exercises/` and presentation slides in `presentations/md2tty/` are designed to be used during guided PSO workshops or as self-paced onboarding material for your engineering teams.

---

## 7. Documentation Index

Before modifying the repository or onboarding workloads, please consult the relevant system guides:

- **Supply Chain & CI/CD**:
  - [Devcontainer User Guide](docs/devcontainers/user_guide.md) — How to configure `.devcontainer/devcontainer.json` builds and map them to workstation configurations.
  - [AI Agentic SDLC & Skill Registry Guide](docs/agentic_sdlc/user_guide.md) — Enforcing code quality, styling, and security via Antigravity SDK and Agent Platform.
  - [Deployment Guide](docs/iac/admin_guide.md) — How to provision sandboxed single-project environments.
- **System Architecture**:
  - [Technical System Overview & Design](docs/workstations/design.md) — Technical stack details and software rendering design of the workstation layers.
  - [Test Plan](docs/workstations/test_plan.md) — Testing philosophy and bats testing orchestration.
- **Event Orchestration (Hackathons)**:
  - [Hackathon Organizer Guide](docs/hackathon_guide.md) — Timeline, network designs, and resource mappings for large-scale event deployments.
- **Contribution & Governance**:
  - [How to Contribute](docs/contributing.md) — Git workflow, Read-only git policies, and bats linting.
  - [Code of Conduct](docs/code-of-conduct.md) — Workspace behavioral standards.
