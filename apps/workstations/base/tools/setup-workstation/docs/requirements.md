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

# Requirements: Cloud Workstation Setup CLI

## 1. Overview

The primary purpose of this tool is to bootstrap user-specific configurations (such as Antigravity CLI settings, MCP configs, and developer dotfiles) dynamically upon a developer's first use of a Cloud Workstation, or when manually re-invoked.

## 2. Goals

- Provide a smooth, interactive onboarding experience (Terminal User Interface) for developers entering a new Cloud Workstation.
- Eliminate the need to bake sensitive or user-specific parameters directly into Docker images.
- Provide a highly flexible, template-driven generation system so the tool is not hardcoded to only configure specific tools, but can be seamlessly extended by administrators.

## 3. Non-Goals

- It is a non-goal to handle complex secret rotation logic; this tool handles static configuration bootstrapping.
- It is a non-goal to act as a system package manager. It writes text files; it does not execute `apt-get install` or manage OS-level dependencies.

## 4. Functional Requirements

### 4.1 Configuration & Templating

- **Dynamic Inputs:** The tool MUST NOT hardcode the prompts in the application logic. The required inputs MUST be defined via an external configuration file. This allows administrators to easily add or remove setup questions.
- **Template Engine:** The tool MUST utilize standard templates (e.g. Go `text/template` format) to generate the final configuration files. Suffixes like `.tmpl` MUST NOT be mandatory in the source repository; the wrapper tool should append `.tmpl` automatically during translation to declare them to the state engine.
- **Template Authoring Abstraction:** The tool MUST abstract away the underlying templating engine's strict naming conventions (e.g., Chezmoi's `dot_` and `private_` prefixes). Template authors MUST be able to define source directories using standard hidden file names (e.g., `.config`) and define file permissions optionally inside the `setup-workstation.yaml` (which defaults to simple filesystem inheritance). The tool will automatically translate these into engine-specific formats at runtime.
- **Hydration:** The tool MUST combine the user's interactive inputs with the source templates to output the finalized files into the developer's `$HOME` directory.

### 4.2 Execution & Idempotency

- **Multiple Invocations:** The tool MUST be safe to call multiple times. It should support updating existing files or replacing them without corrupting the workspace or overwriting manual edits blindly.
- **CLI Configuration:** The tool MUST support explicit CLI flags for configuring its operational paths (e.g. `-c` / `--config` for config file location, `-d` / `--directory` for source templates, `-n` / `--needs-setup` for checking completion status, and `-r` / `--reset` to force a fresh re-prompt using schema defaults).
- **Environment Fallbacks:** The tool SHOULD look for specific Cloud Workstation environment variables (e.g., injected via Terraform) and pre-fill or silently skip the TUI fields if those variables are present.
- **TUI-Only Suggested Defaults:** Default values defined in the schema configuration file (`setup-workstation.yaml`) MUST only be used to seed initial prompt inputs in the TUI during the developer's first run. They MUST NOT act as fallback values if the user explicitly clears an optional field or reruns the tool.
- **Prefilled Values on Rerun:** If manually re-invoked, the tool MUST attempt to parse the previously saved configurations from the user's home directory (e.g., `~/.config/chezmoi/chezmoi.yaml` data) and pre-fill them as defaults inside the TUI form fields, preserving explicit blank values (`""`) if the user previously cleared them.
- **List Generated Files:** Upon successful execution, the tool MUST list all absolute paths of the files that were generated or updated.

### 4.3 Trigger Mechanism

- **Interactive First-Run:** The tool MUST trigger automatically when the user first opens an interactive terminal session in the Cloud Workstation.
- **Shell Agnosticism:** The trigger SHOULD support standard workstation shells (Bash, Zsh) natively.
