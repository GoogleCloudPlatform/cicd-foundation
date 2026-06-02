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

# Antigravity Layer Design Document

## 1. Context and Scope

**Goal**: The Antigravity Layer provides a highly productive, pre-configured desktop environment explicitly tailored for cloud-native engineering, hackathons, and AI research.

**Scope**: This document covers the specific application layer configurations built on top of the GNOME base image.

**Documentation Context**: This layer adheres to the **Thin Layer Philosophy** and **Centralized Configuration** patterns defined in the [GNOME Design Document](../../gnome/docs/design.md). Refer to that document for details on OS lifecycle, Wayland orchestration, and Remote Access.

## 2. Detailed Design: Antigravity-Specific Integration

### Hardware Acceleration Wrapper

A critical role of the post-install hook (`assets/post-install-hooks.d/10_patch_antigravity_desktop.sh`) is modifying the `Exec` path in the Antigravity `.desktop` file to point to a wrapper script (`/usr/local/bin/antigravity`).

**Design Rationale**: Cloud Workstation instances typically lack dedicated GPUs. Electron or Chromium-based desktop applications (like Antigravity) often crash or perform poorly if they attempt hardware-accelerated rendering in a headless container. This wrapper ensures that necessary command-line switches (e.g., `--disable-gpu`, `--disable-software-rasterizer`) are injected when launching the application. This is a mandatory best practice for stability.

### Session Lifecycle & Autostart

The hook also leverages the `desktop_apply_integration` utility to seamlessly integrate the application into the GNOME UX:

1.  **Favorites**: Registers the application as a top-priority (priority 10) dock favorite.
2.  **Autostart**: Symlinks the patched `.desktop` file to `/etc/xdg/autostart/`. The wrapper script ensures that the application waits for the virtual monitor to be initialized by GNOME Shell (via `wait_for_monitor`), ensuring the Antigravity dashboard launches automatically and stably as soon as the session is ready.

## 3. Dev-Ready Tools

By default, the Antigravity layer propagates build arguments to ensure advanced development tools are present:

- **Agent Development Kit (ADK)**: Python tools for building and testing AI agents (`INSTALL_AGENT_DEVELOPMENT_KIT_PYTHON`).
- **Gemini CLI**: Terminal access to Gemini models for automation and persona-driven development.
