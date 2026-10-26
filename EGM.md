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

# Google Cloud CI/CD Foundation & Secure Developer Workstations Blueprint

## System Overview

Provides a Google Cloud CI/CD foundation and layered Cloud Workstations
infrastructure-as-code (Terraform) and container image ecosystem designed for an
Agentic Software Development Lifecycle (SDLC). The repository unifies:

- Multi-environment and single-project Terraform blueprints and modules
  (`infra/`) for provisioning Google Cloud Workstations, Secure Source Manager
  (SSM), Artifact Registry, Cloud Build pipelines (with Skaffold dependency
  resolution, pre-build Gemini agentic code reviews, and Kritis Binary
  Authorization attestation), and Cloud Deploy targets.
- Layered Cloud Workstation container images (`apps/workstations/`),
  standalone Development Containers (`apps/devcontainers/`), a custom CI/CD
  build runner (`apps/build-runner/`), and polyglot Cloud Run / GKE reference
  applications (`apps/*-hello-world/`).
- Modular AI agent persona skills (`skills/`) and validation/governance
  tooling (Go CLI utilities, Python helpers, and Bash lifecycle scripts).
- A dual-runtime terminal and browser Markdown presentation engine
  (`presentations/md2tty/`) and developer CLI helper scripts (`bin/`, `dev/`,
  `tools/`).

## Local Interface & Invariants

- `.pre-commit-config.yaml`: Configures repository-wide active pre-commit
  hooks (`gitleaks`, `keep-sorted`, `prettier`, `gofmt`, `ruff`,
  `ruff-format`, `terraform-fmt`, `shellcheck`, `license-enforcer`,
  `markdown-link-checker`, `bats-bin`, `golangci-lint-persona`, `bats-skills`,
  `pytest-skills`, `pytest-pipelines`, `go-test-persona`,
  `npm-install-preflight`, `vitest`, `bats-preflight`, `bats-preflight-web`,
  `bats-images`, and `oxlint`).
- `.pre-commit-hooks.yaml`: Exports reusable pre-commit hooks (`gitseep`,
  `gitseep-check`, `clean-whitespace`, `verify-locales`, and
  `license-enforcer`) for external consumers.
- `go.mod` (`github.com/GoogleCloudPlatform/cicd-foundation`, Go 1.25.9) &
  `pyproject.toml`: Root Go module and Python workspace dependency
  specifications.
- `AGENTS.md` & `GEMINI.md`: Authoritative AI agent mandates, proximity
  routing table, and 6-step validation lifecycle rules.

## Subdirectories & System Boundaries

- `apps`: [`./apps/EGM.md`](./apps/EGM.md) - Layered Google Cloud Workstations
  container images (`workstations`), custom Cloud Build / Skaffold build
  runner image (`build-runner`), Development Container configurations
  (`devcontainers`), and polyglot reference applications (`go-hello-world`,
  `java-hello-world`, `node-hello-world`, `python-hello-world`).
- `bin`: [`./bin/EGM.md`](./bin/EGM.md) - Shell utility scripts supporting
  local development, environment manifest and `requirements.txt` generation
  (`common.sh`, `generate.sh`), local service execution (`run.sh`), and
  Skaffold testing and Cloud Run deployment (`test.sh`, `cloudrun.sh`).
- `dev`: [`./dev/EGM.md`](./dev/EGM.md) - Shell utility scripts for local
  development and pre-commit workflows targeting `infra/`, automating
  recursive Terraform source formatting (`format-sources.sh`),
  `terraform-docs` module README generation (`generate-docs.sh`), and `tflint`
  execution (`pre-commit.sh`).
- `docs` ([`./docs/style_guides/README.md`](./docs/style_guides/README.md)):
  Project architecture documentation ([`./docs/workstations/design.md`](./docs/workstations/design.md),
  [`./docs/workstations/test_plan.md`](./docs/workstations/test_plan.md)),
  user and admin guides ([`./docs/devcontainers/user_guide.md`](./docs/devcontainers/user_guide.md),
  [`./docs/agentic_sdlc/user_guide.md`](./docs/agentic_sdlc/user_guide.md),
  [`./docs/iac/admin_guide.md`](./docs/iac/admin_guide.md),
  [`./docs/hackathon_guide.md`](./docs/hackathon_guide.md)), governance
  ([`./docs/contributing.md`](./docs/contributing.md),
  [`./docs/code-of-conduct.md`](./docs/code-of-conduct.md)), and language style
  guides (`bash.md`, `docker.md`, `go.md`, `i18n.md`, `python.md`,
  `systemd.md`, `terraform.md`, `typescript.md`).
- `exercises`: [`./exercises/README.md`](./exercises/README.md) - Guided
  hands-on lab instructions (`E0_preparations` through `E4_binary_auth`).
- `infra`: [`./infra/EGM.md`](./infra/EGM.md) - Infrastructure-as-Code root
  directory containing deployable Terraform blueprints
  (`blueprints/workstations`), reusable CI/CD and Cloud Workstations modules
  (`modules/cicd_foundation`, `modules/cicd_pipelines`,
  `modules/cicd_workstations`), the multi-project enterprise hub-and-spoke
  reference architecture (`reference`), and the single-project hub-and-team
  simplified architecture (`simplified`).
- `presentations`: [`./presentations/EGM.md`](./presentations/EGM.md) -
  Interactive presentation packages and slide rendering engines, including the
  `md2tty` dual-runtime terminal (`bin/md2tty.sh`) and browser ES module
  (`src/md2tty.js`) presentation system.
- `skills`: [`./skills/EGM.md`](./skills/EGM.md) - AI agent skills adhering to
  the `agentskills.io` specification (`deploy-workstations`,
  `persona-agent-manager`, `persona-legal`, `persona-oss`, `persona-privacy`,
  `persona-security`, `persona-sre`, `persona-swe`, `persona-ux`,
  `validate-image-updates`), shared shell utilities (`common.sh`), and
  Go/Python/Bash automation and governance tooling.
- `tools`: [`./tools/EGM.md`](./tools/EGM.md) - CI/CD and deployment tooling
  configurations and installation scripts for Cloud Build, Cloud Deploy,
  Kritis, and Tekton (`tools/tekton/EGM.md`).

## Global Invariants

- **Read-Only Git Mandate for Agents**: AI agents must treat Git as strictly
  read-only (`git status`, `git diff`, `git log`) and never stage, commit, or
  push changes.
- **Surgical Pre-Commit Validation**: Pre-commit hooks must be executed
  surgically on changed files (`git diff --name-only | xargs pre-commit run
--files`) rather than via `pre-commit run --all-files`; hooks operating on
  shared Go modules or directories require `require_serial: true` and must
  support the `--` flag separator via `flag.Parse()`.
- **Internationalization (i18n)**: User-facing interfaces
  (`apps/workstations/preflight-web`, `presentations/md2tty`,
  `skills/persona-legal/scripts`) must support all 6 official United Nations
  languages (`ar`, `en`, `es`, `fr`, `ru`, `zh`) with locale JSON entries
  sorted alphabetically by `id`.
- **Artifact Integrity & Supply Chain Security**: All third-party binaries,
  SDK archives, and IDE tarballs downloaded during container image builds must
  verify SHA-256 checksums (`sha256sum -c -`), and third-party APT repository
  keys must be stored as ASCII-armored `.asc` keyrings.
- **Workstation Layer Lifecycle Separation**: Workstation container layers
  (`apps/workstations/*`) must strictly separate build-time hooks
  (`/build-hooks.d`, `/post-install-hooks.d` orchestrated by
  `configure_workstation.sh` / `setup-workstation`) from boot-time
  initialization (`/etc/workstation-startup.d`, `/etc/profile.d`,
  `/google/scripts/user-setup.d`, and `/tmp/workstation-ready/*.ready`
  readiness sentinels).
- **6-Step Validation Lifecycle**: Technical updates to workstation images
  must follow the sequential lifecycle enforced by
  `skills/validate-image-updates`: (1) Stop workstation (`STATE_STOPPED`), (2)
  Run local tests
  (`skills/validate-image-updates/scripts/run_local_tests.sh`), (3) Monitor
  Cloud Build to `SUCCESS`, (4) Start workstation, (5) Run live Bats
  integration tests
  (`skills/validate-image-updates/scripts/run_integration_tests.sh`), and (6)
  Conduct persona reviews.

## Global Side Effects

- **Google Cloud Resource Provisioning (`infra/`)**: Applying Terraform
  configurations enables GCP APIs and provisions or mutates VPC networks,
  Cloud NAT, firewall policies, Private CA and Secure Source Manager
  instances/repositories, Artifact Registry repositories, Cloud Build triggers
  and worker pools, Secret Manager secrets, KMS keys, Binary Authorization
  attestors/policies, Cloud Deploy pipelines/targets, GKE Autopilot clusters,
  Cloud Scheduler jobs, and Cloud Workstations clusters, configs, and
  instances.
- **Container Image Builds & Registry Pushes (`apps/`, `bin/`)**: Building
  workstation layers, DevContainers, or sample applications via Skaffold,
  Docker Buildx, `ko`, or Cloud Buildpacks downloads upstream dependencies,
  compiles binaries/bundles, and pushes container images and build caches to
  Artifact Registry.
- **Workstation Host & Session Mutations (`apps/workstations/`,
  `skills/persona-sre/`)**: Workstation startup and management
  scripts configure systemd/D-Bus user sessions (UID `1000`), launch headless
  GNOME Wayland / GNOME Remote Desktop (`grdctl`) / TigerVNC / Chrome Remote
  Desktop (`CRD`) / Apache Guacamole / PulseAudio / Preflight services, open
  TCP tunnels via `gcloud`, and update `$HOME/.ssh/config`.
- **In-Place Repository Hygiene (`dev/`, `skills/`)**: Pre-commit and skill
  scripts rewrite source file SPDX license headers (`license_enforcer`),
  synchronize SBOM license texts (`sync_license_assets.sh`), refresh APT GPG
  keyrings (`update_gpg_keys.sh`), format Terraform configs
  (`format-sources.sh`), and regenerate Terraform module documentation
  (`generate-docs.sh`).

## System Verification

- Local Validation Suite:
  `./skills/validate-image-updates/scripts/run_local_tests.sh`
- Full Validation Suite (Local + Live Workstation Integration):
  `./skills/validate-image-updates/scripts/run_all_tests.sh`
- Surgical Pre-Commit Check: `git diff --name-only | xargs pre-commit run
--files`
