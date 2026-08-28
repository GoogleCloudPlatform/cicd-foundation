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

# Cloud Workstation Setup Tool

The `setup-workstation` CLI is an interactive, TUI-driven bootstrapping utility for Google Cloud Workstations. It dynamically provisions user-specific configurations (like GCP Project IDs and MCP server URLs) using Chezmoi.

## Documentation

For deep-dive architectural details and requirements, please see:

- [Requirements (PRD)](docs/requirements.md)
- [Design Document](docs/design.md)

## Development

To build the tool locally:

```bash
go build -o setup-workstation ./cmd/setup-workstation
```

## Usage

To see all available configuration options, run the tool with the `--help` flag:

```bash
./setup-workstation --help
```

```text
Cloud Workstation Setup CLI

Usage:
  setup-workstation [flags]

Flags:
  -c, --config string
    	Path to the configuration YAML (default "/google/etc/setup-workstation.yaml")
  -d, --directory string
    	Path to the template directory (default "/google/etc/setup-workstation.d")
  -n, --needs-setup
    	Check if setup is required and exit (0 if required, 1 if done)
  -r, --reset
    	Force rerun setup ignoring previous config choices
```
