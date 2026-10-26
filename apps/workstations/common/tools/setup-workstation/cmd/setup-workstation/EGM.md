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

# Setup Workstation CLI (`setup-workstation`)

## Overview

CLI entrypoint package (`main`) for the `setup-workstation` utility, responsible
for parsing command-line flags and environment variable defaults (`main.go`,
`cli.go`), checking whether workstation setup is required (`--needs-setup`), and
invoking `internal/setup.Run` with OS interrupt signal handling.

## Interface

- CLI binary `setup-workstation` flags: `-c` / `--config <string>` (config
  YAML path), `-d` / `--directory <string>` (template directory path), `-n` /
  `--needs-setup` (check if setup is required and exit), `-r` / `--reset`
  (force rerun setup ignoring previous config choices).
- Environment variables: `SETUP_CONFIG` (fallback default for `--config`),
  `SETUP_DIRECTORY` (fallback default for `--directory`).
- `func main()` (in `main.go`).
- `func runCLI() (int, error)` (in `main.go`).
- `func parseFlags() (setup.Options, bool)` (in `cli.go`).

## Invariants

- Default `--config` path is `/google/etc/setup-workstation.yaml` when
  `SETUP_CONFIG` is unset or empty.
- Default `--directory` path is `/google/etc/setup-workstation.d` when
  `SETUP_DIRECTORY` is unset or empty.
- In `--needs-setup` (`-n`) mode, exit code `0` indicates setup is required
  (including when `setup.CheckRunnable(opts)` fails so the full run can
  surface the error, or when `--reset` is set, or when
  `setup.IsDone(opts.HomeDir)` is `false`), whereas exit code `1` indicates
  setup is already complete (`!opts.ForceReset &&
setup.IsDone(opts.HomeDir)`).
- In normal execution mode, exit code `0` indicates `setup.Run` succeeded and
  exit code `1` indicates an error occurred.

## Side Effects

- Mutates global `flag.CommandLine` state (`flag.BoolVar`, `flag.StringVar`,
  `flag.Usage`, `flag.Parse`).
- Reads `SETUP_CONFIG`, `SETUP_DIRECTORY`, and user home directory environment
  state (`os.Getenv`, `os.UserHomeDir`).
- Registers OS signal handler for `os.Interrupt` via `signal.NotifyContext`
  during `setup.Run`.
- Writes usage text and error messages to `os.Stderr` and terminates the
  process via `os.Exit`.
- Delegates workstation configuration and template hydration side effects to
  `setup.CheckRunnable`, `setup.IsDone`, and `setup.Run`.
