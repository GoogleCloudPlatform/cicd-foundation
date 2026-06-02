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

# Technical Overview

This document provides a comprehensive summary of all technical features and technologies used across the various layers of the Cloud Workstation blueprint.

## 1. Preflight Layer (Web Frontend & Gateway)

The Preflight layer is responsible for the initial user experience, configuration rendering, and traffic control.

- **Technologies:**
  - **Frontend:** Vanilla TypeScript, Vite, HTML5, Tailwind CSS
  - **Web Server / Gateway:** Nginx
  - **Scripting:** Bash (for rendering configurations and traffic control)
- **Key Features:**
  - **Dynamic Configuration Rendering:** Uses `envsubst` to generate ephemeral credentials and inject configuration variables at runtime.
  - **Content Negotiation:** Nginx uses `sub_filter` to negotiate language settings server-side without relying on cookies.
  - **Health Polling & Backoff:** The web UI implements exponential backoff to poll the backend readiness, hiding connection errors from users.
  - **Localization (i18n):** Full support for multiple languages dynamically loaded by the browser.
  - **Traffic Control:** Employs systemd logic (`permit-traffic.service`) to gate external network access until all backend systems are healthy.

## 2. GNOME Layer (Desktop & Remote Access)

The GNOME layer provides the core remote desktop environment and orchestrates the user's graphical session.

- **Technologies:**
  - **Desktop Environment:** GNOME Shell (Headless Wayland), Mutter
  - **Remote Desktop Protocol:** Apache Guacamole, `gnome-remote-desktop` (RDP), FreeRDP
  - **Orchestration:** Native Systemd (declarative service enablement)
  - **Testing:** Bats-core (Bash Automated Testing System)
- **Key Features:**
  - **Headless Wayland Session:** optimized for containerized environments using software rendering (`LIBGL_ALWAYS_SOFTWARE=1`).
  - **Ephemeral Credentials:** RDP passwords are generated per-startup and never persisted, heavily locking down unauthorized access.
  - **Containerized Guacamole:** Runs Guacamole in a `docker-in-docker` configuration directly orchestrated by systemd, mapping the ephemeral credentials into `user-mapping.xml`.
  - **Persona-Driven Engineering Standards:** Implements strict Bash, TypeScript, Docker, and Systemd style guides.

## 3. Android Studio for Platform Layer (AI & Advanced Tools)

The Android Studio for Platform layer extends the workstation with enterprise-grade development tools and AI-driven workflows.

- **Technologies:**
  - **AI Agent / CLI:** Gemini CLI
  - **Agent Skills:** Custom Markdown-based skill instructions for persona adoption and specific workflows.
- **Key Features:**
  - **Native AI Integration:** The **Gemini CLI** is a first-class citizen of the blueprint, providing developers with context-aware, multimodal AI assistance directly in their terminal.
  - **Skill Modular System:** Contains specific skills (e.g., `persona-sre`, `persona-legal`, `persona-swe`) that guide AI behavior safely inside the workspace.
  - **Automated Traceability & Reporting:** Maintains strict standards for AI-generated code reviews and operational reports (SRE, SEC, etc.).
  - **Build-time Hooks:** Enables clean, isolated tool installations (`assets/build-hooks.d/`) without dirtying the core desktop OS.
