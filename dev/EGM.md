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

# Development Utilities (`dev`)

## Overview

Shell utility scripts for local development and pre-commit workflows targeting
the repository's Terraform infrastructure (`infra/`), automating recursive
source formatting (`terraform fmt`), module README documentation generation
(`terraform-docs`), and recursive linting (`tflint`).

## Interface

- `format-sources.sh`: CLI script with no arguments that runs `terraform fmt
-recursive` against `<repo_root>/infra/`.
- `generate-docs.sh [--help] [--path-to-modules <path>]`: CLI script (defining
  internal helper `usage()`) that runs `terraform-docs markdown` on each
  top-level directory or symlink inside `<path>` (defaults to
  `<repo_root>/infra/modules`).
- `pre-commit.sh`: CLI script with no arguments that sequentially runs
  `format-sources.sh`, `generate-docs.sh`, and `tflint --recursive --chdir
"$SCRIPT_DIR/../infra/" 2>&1`.

## Invariants

- Directory layout assumption: all three scripts resolve canonical `SCRIPT_DIR`
  from `$0`, requiring `dev/` to be located at the same directory depth as
  `infra/` (`../infra/` and `../infra/modules`).
- External tool dependencies: `terraform`, `terraform-docs`, and `tflint` must
  be available in `PATH`.
- `generate-docs.sh` wraps generated markdown in
  `<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->` and
  `<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->` delimiters and only outputs
  `inputs` and `outputs` sections.
- `generate-docs.sh` discovers modules using `find "$MODULES_DIR" -maxdepth 1
\( -type d -o -type l \) | grep -v "$MODULES_DIR$"`, restricting generation
  to immediate child directories or symlinks.
- All three scripts adhere strictly to POSIX `/bin/sh` (`[ ... ]` conditionals
  and quoted directory expansions).

## Side Effects

- `format-sources.sh` rewrites Terraform source files in-place under
  `<repo_root>/infra/` via `terraform fmt -recursive`.
- `generate-docs.sh` changes the working directory (`cd`) into each module
  directory and creates or modifies `README.md` in-place via `terraform-docs`.
- `pre-commit.sh` performs the in-place modifications of both
  `format-sources.sh` and `generate-docs.sh`, and executes `tflint` across
  `../infra/` with `stderr` redirected to `stdout` (`2>&1`).
