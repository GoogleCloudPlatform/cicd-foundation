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

# gVisor Antigravity DevContainer

This guide explains how to start the `gvisor-antigravity` DevContainer using gVisor (`runsc`) and how to utilize the Antigravity CLI within it.

## Prerequisites: Custom CWS Image

To support this setup, you first need a Cloud Workstations (CWS) environment equipped with Development Containers and gVisor.

The [`codeoss-devcontainer-gvisor-terraform`](../codeoss-devcontainer-gvisor-terraform) setup in `apps/devcontainers` can be utilized to build this custom CWS image.

Once you have started a CWS instance running the custom image built by the `cicd-foundation`, you can verify the runtime environment. The gVisor binaries will be available at `/usr/local/bin/gvisor-bin/`, and you can confirm `runsc` is registered by checking Docker's configuration:

```bash
docker info | grep -i runtime
```
*(This command should list `runsc` among the available runtimes).*

## Project Configuration

To use the Antigravity DevContainer, set up your project's `.devcontainer/devcontainer.json` to specify `runsc` as the runtime and point to the custom image.

Example configuration:

```json
{
  "name": "devcontainer-gvisor-antigravity",
  "image": "$REGION-docker.pkg.dev/$PROJECT_ID/cicd-foundation/devcontainer-gvisor-antigravity:latest",
  "runArgs": [
    "--runtime=runsc"
  ],
  "containerEnv": {
    "AGY_ADC_AUTH": "true"
  },
  "mounts": [
    "source=${env:HOME}/.config/antigravity,target=/home/vscode/.config/antigravity,type=bind,consistency=cached"
  ]
}
```
*(Note: Replace `$REGION` and `$PROJECT_ID` with your actual Google Cloud region and project ID).*

## Authentication

Before running commands, you must authenticate the Antigravity CLI. The recommended approach is to use Application Default Credentials (ADC) and set the `AGY_ADC_AUTH` environment variable (as configured in the `devcontainer.json` example above).

1. Ensure ADC is configured in your environment.

For detailed authentication instructions, see the official documentation:
[Application Default Credentials (ADC) in Antigravity CLI](https://antigravity.google/docs/enterprise#application-default-credentials-adc-in-antigravity-cli).

## Execution

Before bringing up the DevContainer, ensure that the local directory for persisting authentication state exists:
```bash
mkdir -p ~/.config/antigravity
```

Once your CWS instance is running and the `.devcontainer.json` is configured, you can bring up the DevContainer and execute commands.

Bring up the DevContainer:
```bash
devcontainer up
```

Execute an Antigravity (`agy`) command inside the gVisor-secured container:
```bash
devcontainer exec agy -p "Create a Hello World example in a fun programming language."
```
