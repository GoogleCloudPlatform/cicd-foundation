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

# CI/CD Pipelines Scripts (`scripts`)

## Overview

Contains Python helper utilities and Cloud Build shell script templates for the
[`cicd_pipelines`](../EGM.md) Terraform module. The directory provides
build-time transitive Skaffold dependency resolution for Terraform
(`resolve_skaffold_deps.py`), pre-build multi-persona agentic code review
orchestration (`agentic_runner.py`), and shell step templates for repository
cloning (`clone.sh.template`), Skaffold image building (`build.sh.template`),
Artifact Registry digest resolution and `:latest` tagging
(`fetch_image_digest.sh.template`), Kritis vulnerability signing
(`vulnsign.sh.template`), and Cloud Deploy release creation
(`create_release.sh.template`).

## Interface

- `agentic_runner.py`: CLI script (`/usr/bin/python3
infra/modules/cicd_pipelines/scripts/agentic_runner.py`) configured via
  environment variables (`SKAFFOLD_PATH`, `GCP_PROJECT`, `MODEL_LOCATION`,
  `GCP_LOCATION`, `AGENT_MODEL`, `AGENT_PERSONAS`, `AGENT_PROMPT`,
  `AGENT_RATE_LIMIT_DELAY`, `AGENT_TIMEOUT`); defines `main()`,
  `run_persona_agent(persona, prompt, model_name, project_id, location)`,
  `run_persona_agent_with_delay(delay, persona, prompt, model_name,
project_id, location)`, and instruction constants
  `AUDITOR_PERSONA_INSTRUCTION_TEMPLATE`, `ORCHESTRATOR_INSTRUCTION`, and
  `STANDARD_REVIEW_INSTRUCTION`.
- `resolve_skaffold_deps.py`: Terraform `data "external"` CLI script accepting
  stdin JSON `{"skaffold_path": str, "repo_root": str}` and emitting stdout
  JSON `{"included_files": str}`; defines `parse_requires_from_yaml(content:
str) -> list[str]`, `get_transitive_deps(skaffold_path: str, repo_root:
str = ".") -> list[str]`, `resolve_query(query: dict[str, str]) -> dict[str,
str]`, and `main() -> None`.
- `clone.sh.template`: Cloud Build `clone` step script template parameterized
  by `${_GIT_CLONE_URL}`, `${_IS_GIT_REPO_WEBHOOK}`, `${_GIT_REPO_REF}`, and
  `${COMMIT_SHA}`.
- `build.sh.template`: Cloud Build `build` step script template parameterized
  by `${_SKAFFOLD_DEFAULT_REPO}`, `${_SKAFFOLD_OUTPUT}`, and
  `${_SKAFFOLD_QUIET}`.
- `fetch_image_digest.sh.template`: Cloud Build `fetchImageDigest` step script
  template parameterized by `${_SKAFFOLD_OUTPUT}`, producing `images.txt` and
  `<DIGEST_HASH>.digest` files.
- `vulnsign.sh.template`: Cloud Build `vulnsign` step script template
  parameterized by `${_KRITIS_POLICY_BASE64}`, `${_SKAFFOLD_PATH}`,
  `${_KMS_KEY_NAME}`, `${_KMS_DIGEST_ALG}`, and `${_NOTE_NAME}`.
- `create_release.sh.template`: Cloud Build `createRelease` step script
  template parameterized by `${SHORT_SHA}`, `${_PIPELINE_NAME}`,
  `${_SKAFFOLD_OUTPUT}`, `$COMMIT_SHA`, `$REVISION_ID`, `$BUILD_ID`,
  `${_REGION}`, and `${_NAMESPACE}`.

## Invariants

- `agentic_runner.py`: When `<SKAFFOLD_PATH>/.agentic/review.py` exists,
  default persona orchestration is bypassed and the script exits with the
  custom script's return code; under SEC-01 compliance, if `os.getuid() == 0`,
  the custom script must be executed in a network-gated namespace as user
  `nobody` (`unshare -n runuser -u nobody -- python3 <path>`).
- `agentic_runner.py`: When running standard or persona reviews,
  `GCP_PROJECT`, `AGENT_MODEL`, and either `MODEL_LOCATION` or `GCP_LOCATION`
  must be non-empty in the environment or the process exits with status `1`.
- `agentic_runner.py`: Persona reviews are staggered by `i *
RATE_LIMIT_DELAY_SECONDS` and wrapped in `asyncio.wait_for(...,
timeout=AGENT_TIMEOUT_SECONDS)` so individual persona timeouts or exceptions
  return `(persona, "ERROR: ...")` without aborting `asyncio.gather`.
- `resolve_skaffold_deps.py`: Must conform to the Terraform `data "external"`
  protocol by always printing a single JSON object with key `"included_files"`
  to stdout, gracefully degrading to regex parsing when `PyYAML` is
  unavailable and ignoring file read or JSON parsing errors.
- `resolve_skaffold_deps.py`: Breadth-First Search normalizes paths
  (`os.path.normpath(current_directory).lstrip("./")`) and tracks
  `visited_directories` to prevent cyclic traversal loops.
- Build step pipeline ordering and working directory contract:
  `build.sh.template` and `fetch_image_digest.sh.template` run inside
  `${_SKAFFOLD_PATH}` to produce `${_SKAFFOLD_OUTPUT}`, `images.txt`, and
  `<DIGEST_HASH>.digest` files; `vulnsign.sh.template` runs from the workspace
  root and reads `./${_SKAFFOLD_PATH}/images.txt` and
  `./${_SKAFFOLD_PATH}/<DIGEST_FILENAME>`; `create_release.sh.template` runs
  inside `${_SKAFFOLD_PATH}` and consumes `${_SKAFFOLD_OUTPUT}`.

## Side Effects

- `agentic_runner.py`: Spawns `git` subprocesses (`git rev-parse
--is-inside-work-tree`, `git diff --name-only HEAD~1`, `git diff
--name-only`) or custom `.agentic/review.py` subprocesses
  (`unshare`/`runuser`/`python3`), makes network calls to Vertex / Agent
  Platform via `google.antigravity.Agent.chat()`, and writes consolidated
  review output to `report.md`.
- `resolve_skaffold_deps.py`: Reads JSON from `stdin`, traverses and reads
  `skaffold.yaml` files across the repository filesystem, and writes JSON to
  `stdout`.
- `clone.sh.template`: Executes `git clone`, `git checkout`, and `git reset
--hard`, performing network I/O and mutating `/workspace`.
- `build.sh.template`: Executes `skaffold build`, building container images,
  pushing them to `${_SKAFFOLD_DEFAULT_REPO}`, and writing artifact metadata
  to `${_SKAFFOLD_OUTPUT}`.
- `fetch_image_digest.sh.template`: Reads `${_SKAFFOLD_OUTPUT}`, writes
  `images.txt` and `<DIGEST_HASH>.digest` files to disk, and executes `gcloud
artifacts docker images describe` and `gcloud artifacts docker tags add`
  (mutating `:latest` tags in Artifact Registry).
- `vulnsign.sh.template`: Creates and removes a temporary policy file via
  `mktemp` and `rm -f`, reads `images.txt` and `.digest` files, and invokes
  `/kritis/signer` to evaluate vulnerabilities and attach attestations via KMS
  and Container Analysis.
- `create_release.sh.template`: Executes `gcloud deploy releases create` to
  create a new release in Cloud Deploy.
