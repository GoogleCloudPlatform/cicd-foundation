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

# AI Agents Instructions: Global Mandates

This repository defines a highly customized Google Cloud Workstation environment. Strict adherence to these global mandates is required for any AI agent.

## 1. Repository Management & Git Constraints

**CRITICAL MANDATE: Git is strictly READ-ONLY.**

As an AI agent, you must **NEVER** use `git` commands to manage the repository, branches, or commits, nor should you stage or push changes. Staging and committing are the exclusive responsibility of the human user.

You may use `git` exclusively for **read-only analysis** (`git status`, `git diff`, `git log`).

**Agent-Friendly Validation**: The `gitseep-check` pre-commit hook is technically optimized for agents. It supports a **`CheckMode`** that permits validation of geological stratigraphy even when the worktree is **dirty** (contains unstaged agent changes), ensuring that technical refactors never block CI compliance.

**Mandates for Pre-commit Integration**:

- **Surgical Validation**: Never run `pre-commit run --all-files`. Always target validation surgically using `xargs` to pass only the changed files (e.g., `git diff --name-only | xargs pre-commit run --files`).
- **Concurrency Safety**: Hooks that perform operations on shared directories or Go modules (e.g., `golangci-lint`, `go test`) MUST be configured with `require_serial: true` in `.pre-commit-config.yaml` to prevent parallel execution conflicts.
- **Argument Robustness**: Custom hooks MUST utilize the `--` separator in their `entry` definition to ensure that filenames are never interpreted as command-line flags. All Go-based utilities MUST use `flag.Parse()` to correctly support this convention.

## 2. Language & Engineering Standards

- **Inclusive Language**: All code, configuration, and documentation MUST use inclusive terminology. utilize alternatives like `primary` or `main` instead of `master`, and `placeholder` or `mock` instead of `dummy`.
- **i18n & Global Reach**: Full i18n support is required across all 6 official United Nations languages (ar, en, es, fr, ru, zh). No hardcoded user-facing strings are permitted. See the [i18n Style Guide](docs/style_guides/i18n.md) for technical formatting rules.
- **Sorted Lists**: Utilize `go/keep-sorted` directives to maintain alphabetical order in source code and configuration files for collections with multiple elements. Do not use `keep-sorted` for single-element lists. For localized JSON files, ensure entries are sorted alphabetically by ID (enforced by the `verify-locales` pre-commit hook).

## 3. Core Architectural Mandates

- **Strategy Pattern (Projection)**: Tree-building logic in `HistoryPipeline` must be abstracted via the `ProjectionStrategy` interface to allow for multiple reconstruction models (e.g., State Projection vs. Full Replay).
- **Event Bus (UI)**: TUI components must utilize the internal `EventBus` (`ui/bus.go`) for decoupled pipeline event distribution, avoiding direct channel propagation.
- **Path-Trie Optimization**: All file-to-bedrock matching must use the optimized `PathTrie` in `GeologicalMatcher` to ensure $O(K)$ lookup performance on large strata.
- **Sequential Discovery**: History scanning must be performed sequentially in `Discover` to maintain deterministic stability with the non-thread-safe `go-git` object resolution, using a central `repoMu` mutex for safety.
- **Shell Dependency Injection**: All system command executions (e.g., `pre-commit`, `worktree`) must be performed via the `ShellService` interface to enable deterministic testing and mock-based validation.

## 4. Agent Validation Lifecycle

Every technical change MUST follow this sequential workflow:

1.  **Stop Workstation**: Ensure the instance is in `STATE_STOPPED`.
2.  **Run Local Tests**: Execute `skills/validate-image-updates/scripts/run_local_tests.sh`.
3.  **Monitor Build**: Wait for the Cloud Build to reach `SUCCESS`.
4.  **Start Workstation**: Only after a successful build.
5.  **Run Integration Tests**: Execute integration suites on the live instance.
6.  **Persona Reviews**: Conduct in-depth persona reviews (UX, SEC, SRE, etc.) after validation.

## 5. Global Agent Skills (Foundation)

These global skills are available within the `skills/` directory:

- **`validate-image-updates`**: Enforces the mandatory 6-step validation workflow.
- **`persona-swe`**: Software Engineering mandates and history refactoring.
- **`persona-sre`**: System resilience and service orchestration.
- **`persona-security`**: Vulnerability auditing and system hardening.
- **`persona-ux`**: Design language, layout stability, and accessibility.
- **`persona-legal`**: Licensing, copyrights, and SBOM compliance.
- **`persona-oss`**: Upstream-first and community standards.
- **`persona-privacy`**: Data handling and privacy regulation compliance.
- **`persona-agent-manager`**: Skill lifecycle and agent orchestration.

## 6. Module-Specific Proximity Router

AI agents must follow local instructions when operating within a specific module:

- 👉 **[Preflight Dashboard (Frontend)](apps/workstations/preflight/AGENTS.md)**: SPA model, i18n standards, and local hot-patching.
- 👉 **[GNOME Desktop (Layer)](apps/workstations/gnome/AGENTS.md)**: Extension compatibility and systemd lifecycle.
- 👉 **[ASfP IDE (Layer)](apps/workstations/android-studio-for-platform/AGENTS.md)**: Wayland backend and AOSP toolchain.

## 7. Agent Skills Specification (Standard)

All agent skills (files named `SKILL.md`) MUST adhere to the `agentskills.io` specification. The YAML frontmatter MUST be located at the absolute beginning of the file (Line 1).

### Mandatory Metadata Fields

- **`name`**: The unique identifier for the skill (e.g., `persona-swe`).
- **`description`**: A concise summary of the skill's purpose.
- **`license`**: The SPDX license identifier (Standard: `Apache-2.0`). For `SKILL.md` files, this field serves as the authoritative license declaration; a physical comment header is not required.

### Optional & Extension Fields

- **`allowed-tools`**: A space-separated string of paths (relative to repo root) to executable scripts or tools owned by this skill.
- **`metadata`**: A mapping for project-specific extensions:
  - **`author`**: The authoritative maintainer. MUST match the active user's Git identity.
  - **`resources`**: A list of paths (relative to repo root) to authoritative documentation or style guides this skill MUST enforce.

### Validation

Technical health is enforced by the `skills/persona-agent-manager/tests/validate_skill.bats` suite. Agents MUST run this suite after any modification to a `SKILL.md` file.

---

👉 **[Full Documentation Index](README.md)**
