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

# Setup Workstation: Examples

This directory contains examples for configuring and utilizing the `setup-workstation` CLI to bootstrap development environments.

## Structure

1. `setup-workstation.yaml.example`: A config example that defines the fields (e.g., `gcp_project`, `mcp_server_url`) to collect from the developer either via their environment variables or via an interactive Terminal User Interface (TUI).
2. `templates/`: An example directory containing templates (e.g., `settings.json`). The template engine uses the Go `text/template` format to inject the answers collected by the manifest dynamically.

## Testing Locally

If you want to test these examples locally on your machine, you can run the CLI directly and override the target paths using environment variables:

```bash
# 1. Ensure you have built the CLI
go build -o setup-workstation main.go

# 2. Run the tool pointing to these examples
export SETUP_CONFIG="$(pwd)/examples/setup-workstation.yaml"
export SETUP_SOURCE="$(pwd)/examples/templates"
./setup-workstation
```

The tool will parse the config, prompt you for any missing fields (like the GCP Project), and then execute `chezmoi` to map the templates into your actual `$HOME` directory!

> **Note**: This will write actual files to your home directory (e.g., `~/.gemini/antigravity-cli/settings.json`) so be mindful if you have existing configurations!
