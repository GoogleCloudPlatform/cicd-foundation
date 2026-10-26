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

# Cloud Workstations Applications (`workstations`)

## Overview

Houses the hierarchical Google Cloud Workstations custom container image layers,
the TypeScript/Vite Preflight web application (`preflight-web`), and the
`setup-workstation` Go onboarding CLI. The image hierarchy progresses from
`common` -> `preflight` -> (`codeoss`, `intellij`, `remote-desktop` -> `gnome`
-> `android-studio-for-platform`, `antigravity`, `antigravity2`), with
`codeoss-devcontainer-intellij` extending `codeoss`.

## Subdirectories & Boundaries

- **Common Base Layer**: [`./common/EGM.md`](./common/EGM.md) - Foundational
  systemd PID 1 lifecycle, `nftables` ingress traffic gating,
  DinD/gVisor/Devcontainers setup, centralized build orchestrator
  (`configure_workstation.sh`), and the `setup-workstation` Go CLI tool.
- **Preflight Layer**: [`./preflight/EGM.md`](./preflight/EGM.md) - Nginx port
  `80` reverse proxy, boot-time template/credential renderer
  (`config_rendering.sh`), multi-protocol readiness probe
  (`backend_readiness_probe.sh`), and `update-preflight` hot-patch skill.
- **Preflight Web SPA**: [`./preflight-web/EGM.md`](./preflight-web/EGM.md) -
  TypeScript/Vite/Tailwind single-page application rendering `startup.html`,
  polling `/readyz`, managing i18n/SBOM/SSH command cards, and injecting
  build-time SRI hashes.
- **Remote Desktop Layer**:
  [`./remote-desktop/EGM.md`](./remote-desktop/EGM.md) - Apache Guacamole
  (`guacd`/`guacamole`), TigerVNC, Chrome Remote Desktop (`CRD`), and
  WebSocket PulseAudio bridge (`audio_streamer.js` +
  `guacamole-audio-bridge`).
- **GNOME Desktop Layer**: [`./gnome/EGM.md`](./gnome/EGM.md) - Headless
  Wayland + Mutter GNOME Shell desktop, native RDP (`grdctl`), display
  readiness polling (`wait_for_monitor`), and `.desktop` dock/autostart
  integration (`desktop_integration.sh`).
- **Android Studio for Platform Layer**:
  [`./android-studio-for-platform/EGM.md`](./android-studio-for-platform/EGM.md)
  - AOSP/AAOS (`VCAR`) development environment with ASfP IDE on Wayland,
    Cuttlefish Virtual Device (`CVD`) packages and scripts, and optional
    ABFS support.
- **Antigravity Layer**: [`./antigravity/EGM.md`](./antigravity/EGM.md) -
  APT-packaged Antigravity IDE layered onto `gnome` with
  `/usr/local/bin/antigravity` stability wrapper and dock/autostart
  registration.
- **Antigravity 2.0 Layer**:
  [`./antigravity2/EGM.md`](./antigravity2/EGM.md) - Tarball-packaged
  Antigravity 2.0 IDE (`/opt/Antigravity-x64`) layered onto `gnome` with
  SHA-256 verification and headless GPU bypass.
- **IntelliJ Ultimate Layer**: [`./intellij/EGM.md`](./intellij/EGM.md) -
  Rebases the predefined IntelliJ Ultimate image onto `preflight` + `common`
  and registers `remote-dev-server` for JetBrains Gateway.
- **Code-OSS Devcontainer IntelliJ Layer**:
  [`./codeoss-devcontainer-intellij/EGM.md`](./codeoss-devcontainer-intellij/EGM.md)
  - Extends `codeoss` with host SSH on port `2222` and a pre-cached IntelliJ
    Ultimate devcontainer on port `22`.
- **Code-OSS Layer**: [`./codeoss/EGM.md`](./codeoss/EGM.md) - Rebases the
  predefined Code-OSS workstation image onto `preflight` + `common` with
  systemd-managed `code-oss.service` on port `8080`, gVisor (`runsc`), and the
  DevContainer CLI.
- **Code-OSS Devcontainer gVisor Terraform**:
  [`./codeoss-devcontainer-gvisor-terraform/EGM.md`](./codeoss-devcontainer-gvisor-terraform/EGM.md)
  - `.devcontainer` and Skaffold configuration with gVisor (`runsc`),
    Terraform, and a custom DevContainer feature script
    (`.devcontainer/features/devcontainer-cli-installer/install.sh`) that
    installs `@devcontainers/cli`.

## Interface

- [`./common/EGM.md`](./common/EGM.md): `/google/scripts/common.sh`,
  `/google/scripts/entrypoint.sh`,
  `/google/scripts/build/configure_workstation.sh`,
  `/google/scripts/build/install_functions.sh`, and
  `/google/bin/setup-workstation`.
- [`./preflight/EGM.md`](./preflight/EGM.md):
  `/google/scripts/config_rendering.sh`,
  `/google/scripts/backend_readiness_probe.sh`,
  `/google/scripts/build/build_web.sh`, and `skills/update-preflight`.
- [`./preflight-web/EGM.md`](./preflight-web/EGM.md): `startup.ts`,
  `config_module.ts`, `health_module.ts`, `i18n_module.ts`, `sbom_module.ts`,
  `shortcuts_module.ts`, `ssh_card_module.ts`, `ui_module.ts`, and
  `inject-sri.cjs`.
- [`./remote-desktop/EGM.md`](./remote-desktop/EGM.md):
  `/google/scripts/audio_streamer.js`, `/google/scripts/fetch_guacamole.sh`,
  and `guacamole-audio-bridge`.
- [`./gnome/EGM.md`](./gnome/EGM.md): `/google/scripts/desktop_utils.sh`
  (`wait_for_monitor`), `/google/scripts/start_gnome_session.sh`,
  `/google/scripts/configure_rdp.sh`, and
  `/google/scripts/build/desktop_integration.sh`.
- [`./android-studio-for-platform/EGM.md`](./android-studio-for-platform/EGM.md):
  `/google/scripts/build_aosp.sh`, `/google/scripts/build_vcar.sh`,
  `/google/scripts/start_vcar_cvd.sh`, and `/google/scripts/stop_vcar_cvd.sh`.
- [`./antigravity/EGM.md`](./antigravity/EGM.md),
  [`./antigravity2/EGM.md`](./antigravity2/EGM.md),
  [`./intellij/EGM.md`](./intellij/EGM.md), and
  [`./codeoss-devcontainer-intellij/EGM.md`](./codeoss-devcontainer-intellij/EGM.md):
  IDE layer build, startup, and user-setup hooks.

## Invariants

- All image layers execute `/google/scripts/build/configure_workstation.sh` at
  build time (`build-hooks.d` -> APT -> `post-install-hooks.d` ->
  `desktop_apply_integration`) and boot via `/google/scripts/entrypoint.sh` ->
  `start_systemd.sh` (`PID 1`).
- External ingress traffic is blocked via `nftables` during boot until
  `permit-traffic.service`, and `/readyz` returns `x-app-status: STARTING`
  until `backend_readiness_probe.sh` confirms all configured protocols are
  ready.
- Graphical layers (`gnome` and descendants) run headlessly on Wayland
  (`GDK_BACKEND=wayland`) with automatic `llvmpipe` software rendering
  fallback when `WORKSTATION_GPU_ENABLED=false` and require GUI wrappers to
  await `wait_for_monitor`.

## Side Effects

- Builds layered container images, manages systemd services, `nftables` rules,
  DinD, Guacamole/RDP/VNC/CRD servers, and PulseAudio WebSocket bridges,
  serves the `preflight-web` dashboard via Nginx, and provisions user home
  directories via `setup-workstation` and `chezmoi`.
