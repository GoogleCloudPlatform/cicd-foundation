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

# Setup Workstation Core (`setup`)

## Overview

Package `setup` (in `internal/setup`) orchestrates interactive and
environment-driven workstation configuration, user input collection via
`charmbracelet/huh` forms, Chezmoi source template preparation (dotfile and
permission prefix translation), and template hydration/deployment using Chezmoi.

## Interface

- `type Options struct { HomeDir string; ConfigPath string; SourceDir string;
ForceReset bool; FormRunner func(*huh.Form) error; Stdout io.Writer; Stderr
io.Writer }`
- `type Config struct { Inputs []Input `yaml:"inputs"`; Permissions
[]PermissionRule `yaml:"permissions"` }`
- `type PermissionRule struct { Path string `yaml:"path"`; Mode string
`yaml:"mode"` }`
- `type Input struct { ID string `yaml:"id"`; Prompt string `yaml:"prompt"`;
Description string `yaml:"description"`; Default string `yaml:"default"`;
DefaultEnv string `yaml:"default_env"`; Required bool `yaml:"required"`;
Validation struct { Type string `yaml:"type"`; Options []string
`yaml:"options"`}`yaml:"validation"` }`
- `type Shell interface { Run(ctx context.Context, name string, args
...string) error; Output(ctx context.Context, name string, args ...string)
([]byte, error) }`
- `type OSShell struct{}`
- `func (s *OSShell) Run(ctx context.Context, name string, args ...string)
error`
- `func (s *OSShell) Output(ctx context.Context, name string, args ...string)
([]byte, error)`
- `func Run(ctx context.Context, opts Options, sh Shell) error`
- `func IsDone(homeDir string) bool`
- `func CheckRunnable(opts Options) error`

## Invariants

- `CheckRunnable` requires `opts.ConfigPath` to exist and `opts.SourceDir` to
  be an existing, non-empty directory before setup proceeds.
- YAML configuration decoding enforces strict schema checking via
  `yaml.Decoder.KnownFields(true)`.
- Inputs with a non-empty `DefaultEnv` matching a non-empty environment
  variable are pre-populated and skipped during interactive form prompting.
- When `opts.ForceReset` is `false`, previous answers from
  `~/.config/chezmoi/chezmoi.yaml` take precedence over schema `Default`
  values as initial form suggestions.
- Inputs with `Required: true` reject empty string submissions during
  interactive validation; Inputs with `Validation.Type == "enum"` and
  non-empty `Options` render as select fields.
- Every `Input.ID` defined in `Config.Inputs` is guaranteed to exist in the
  answers map (defaulting to `""`) before writing Chezmoi data to satisfy
  Chezmoi's `missingkey=error` template behavior.
- Chezmoi data file (`~/.config/chezmoi/chezmoi.yaml`) is always written with
  `0600` permissions under a top-level `data` key.
- Template source files are staged into a temporary directory where path
  segments starting with `.` are renamed to `dot_`, permission rules (`0600`,
  `0755`, `0700`/`0500`, `0444`) map to Chezmoi prefixes (`private_`,
  `executable_`, `private_executable_`, `readonly_`), and non-directory files
  receive a `.tmpl` suffix if not already present.
- Workstation completion state is tracked via a `setup-workstation-done` file
  inside `$XDG_STATE_HOME` (or `~/.local/state` if `XDG_STATE_HOME` is unset).

## Side Effects

- Reads configuration YAML from `opts.ConfigPath`, environment variables via
  `os.Environ`, and previous Chezmoi state from
  `~/.config/chezmoi/chezmoi.yaml`.
- Runs an interactive terminal form via `charmbracelet/huh` (unless overridden
  by `opts.FormRunner` or all inputs are resolved via environment variables).
- Creates `~/.config/chezmoi` (mode `0755`) and writes user answers to
  `~/.config/chezmoi/chezmoi.yaml` (mode `0600`).
- Creates a temporary staging directory in the OS temp folder
  (`setup-workstation-source-*`), copies and renames template files from
  `opts.SourceDir` into it, and removes the temporary directory upon return.
- Executes external `chezmoi apply --source <tmpSourceDir> --force` and
  `chezmoi managed -i files --source <tmpSourceDir> --path-style absolute`
  commands via the `Shell` interface (defaulting to `os/exec` with
  `os.Stdout`/`os.Stderr`).
- Creates the state directory (`$XDG_STATE_HOME` or `~/.local/state`, mode
  `0755`) and writes `done\n` to the `setup-workstation-done` marker file
  (mode `0644`).
- Writes status messages, generated file lists, and warnings to `opts.Stdout`
  and `opts.Stderr` (defaulting to `os.Stdout` and `os.Stderr`).
