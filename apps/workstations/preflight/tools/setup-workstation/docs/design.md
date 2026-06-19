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

# System Design: Cloud Workstation Setup CLI

## 1. Architecture Overview

To satisfy the requirements for dynamic schema-driven inputs, robust idempotency, and template hydration, the system utilizes a **Hybrid Wrapper Pattern**.

The system consists of two primary execution components:

1. **The Wrapper CLI (`setup-workstation`):** A lightweight, interactive frontend (built via Go using `charmbracelet/huh`) responsible for parsing the schema, reading environment variables, rendering the Terminal User Interface (TUI), and collecting answers.
2. **The State Engine (`chezmoi`):** A robust, backend templating engine that natively supports Go `text/template` and idempotent file deployment.

## 2. File System Layout

The system strictly separates immutable administrative blueprints from mutable user state. Platform-provided files are stored in a protected `/google/` directory structure.

### 2.1 System Files (Read-Only Blueprint)

- `/google/bin/setup-workstation` - The executable wrapper CLI.
- `/google/bin/chezmoi` - The underlying templating engine executable.
- `/google/etc/setup-workstation.yaml` - The default schema/config defining required inputs, prompt text, and environment fallbacks.
- `/google/etc/setup-workstation.d/` - The default directory containing the raw source templates (e.g., `.antigravity/settings.json`).

### 2.2 User Files (Generated State)

- `~/.config/chezmoi/chezmoi.yaml` - The main Chezmoi configuration file. The user's answers are serialized into a `data:` block here by the wrapper CLI. On rerun, the wrapper CLI reads this block to prefill inputs in the TUI form.
- `~/.local/state/setup-workstation-done` - A flag file indicating the initial bootstrap has been completed.
- `~/.config/*` - The finalized, hydrated configuration files deployed by the engine.

## 3. Execution Lifecycle

### Phase 1: Infrastructure Provisioning (Docker / Terraform)

1. The custom Docker image is built, baking in the `/google/bin` executables and the `/google/etc` blueprints.
2. Terraform provisions the Google Cloud Workstation, injecting necessary default parameters as environment variables (e.g., `AGY_GCP_PROJECT`, `AGY_MCP_SERVER_URL`).
3. The Dockerfile adds execution hooks into `/etc/profile.d/` (for terminal access) and `/etc/xdg/autostart/` (for GNOME desktop access).

### Phase 2: User Initialization (The Trigger)

1. The user connects to the Cloud Workstation via SSH, IDE Terminal, or the GNOME desktop.
2. The respective execution hook (`99-setup-workstation.sh` or `setup-workstation.desktop`) automatically fires.
3. The hook securely evaluates the `--needs-setup` flag on the Go binary.
4. If setup is required (or if `--reset` is specified), the interactive Terminal User Interface (TUI) is launched on the user's active PTY terminal, blocking execution until the wizard is completed.

### Phase 3: Collection (The Wrapper CLI)

1. The wrapper reads the schema from the path provided via the `--config` CLI flag (which falls back to `/google/etc/setup-workstation.yaml`).
2. If the `--reset` flag is NOT passed, the wrapper looks for previous configurations by loading `~/.config/chezmoi/chezmoi.yaml` and parsing its `data` block.
3. For each defined input:
   - It checks the host environment for the specified fallback variable (`DefaultEnv`). If present, it maps it directly to `answers` and skips prompting for this input entirely.
   - If no env override is present, it prompts the user using a TUI form. The input is prefilled with their previous choice (if available and `--reset` is not passed), falling back to the schema `default` ONLY if it is the first run (or `--reset` was specified).
4. Once all data is collected, the wrapper serializes the answers into the `data:` block within `~/.config/chezmoi/chezmoi.yaml`.

### Phase 4: Hydration & Deployment (The State Engine)

1. The wrapper dynamically replicates the raw templates (`/google/etc/setup-workstation.d/`) to a temporary directory, translating user-friendly hidden directories (e.g., `.gemini`) into Chezmoi's strict syntactical requirements (`dot_gemini`), and automatically appends a `.tmpl` suffix to all file names (if not already present). During this step, the wrapper enforces any optional `permissions` declared in the `setup-workstation.yaml` by injecting `private_` or `executable_` prefixes into the temporary filenames. If no permission is explicitly declared for a file, it strictly inherits the permissions it possessed in the Docker image/Git repository (typically `0644` for files and `0755` for directories/executables).
2. The wrapper silently executes the state engine on the translated templates:  
   `chezmoi apply --source <temp_dir>`
3. Chezmoi reads the `data:` block from `chezmoi.yaml`.
4. Chezmoi parses the Go `text/template` files.
5. **Template Resilience**: The wrapper ensures that every single input defined in the config schema is explicitly injected into the `data:` block. If a key is structurally missing from `answers` (e.g. skipped headlessly), the wrapper injects it as an empty string `""` into the `data:` block. This unblocks the strict Go `text/template` engine's `missingkey=error` constraint, preventing compilation panics. The schema defaults are strictly TUI-level suggestions and are never forcefully re-injected post-run.
6. Chezmoi calculates the diff and idempotently writes the final configurations to the user's `$HOME` directory.
7. **Listing Generated Files:** The wrapper runs `chezmoi managed -i files --source <temp_dir> --path-style absolute` to query Chezmoi for the final target paths of all managed templates, then prints them to the user in a clean bulleted list.
8. The wrapper CLI touches `~/.local/state/setup-workstation-done` to prevent further automatic invocations, and exits cleanly.
