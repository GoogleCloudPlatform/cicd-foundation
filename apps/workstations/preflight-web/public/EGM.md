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

# Preflight Web Public Assets (`public`)

## Overview

Public static assets and runtime configuration templates for the Custom Image
Preflight for Cloud Workstation web application. Contains a placeholder runtime
configuration script (`config.js`), an environment-variable and token
substitution template (`config.js.template`) that populates `window.CWS_CONFIG`,
localized string bundles (`locales/{ar,en,es,fr,ru,zh}.json`), a standalone
privacy notice fragment (`privacy_notice.html`), UI background images
(`background.jpg`, `background-small.jpg`), a static `Curated-SPDX-Manifest`
(`sbom.json`), and full license texts (`licenses/*.txt`).

## Interface

- `window.CWS_CONFIG`: Defined in `config.js.template` with fields
  `connectionId`, `redirectUrl`, `supportedProtocols`, `hostname`,
  `serverLang`, `clientIp`, `timeoutMs`, `autoRedirect`, `projectId`,
  `region`, `clusterName`, `configName`, `hasGuacamole`, `sshPort`,
  `hostSshPort`, and `hasJetbrainsGateway`.
- `public/config.js`: Runtime configuration placeholder script.
- `public/config.js.template`: Template expecting environment variables
  `${DEFAULT_CLIENT_PROTOCOL}`, `${DEFAULT_REDIRECT_URL}`,
  `${SUPPORTED_PROTOCOLS}`, `${HOSTNAME}`, `${CLIENT_IP}`, `${TIMEOUT_MS}`,
  `${AUTO_REDIRECT}`, `${PROJECT_ID}`, `${REGION}`, `${CLUSTER_NAME}`,
  `${CONFIG_NAME}`, `${HAS_GUACAMOLE}`, `${SSH_PORT}`, `${HOST_SSH_PORT}`,
  `${HAS_JETBRAINS_GATEWAY}`, and token `@@SERVER_LANG@@`.
- `public/locales/{ar,en,es,fr,ru,zh}.json`: Localized translation bundles for
  all 6 official United Nations languages.
- `public/privacy_notice.html`, `public/background.jpg`, &
  `public/background-small.jpg`: Static HTML fragment and background assets.
- `public/sbom.json` & `public/licenses/*.txt`: JSON document with schema
  fields `bomFormat`, `specVersion`, `metadata`, `licenses`, and `components`,
  paired with static license text files (`Apache-2.0.txt`, `BSD-2-Clause.txt`,
  `CC0-1.0.txt`, `GPL-2.0-only.txt`, `GPL-3.0-only.txt`, `MIT.txt`,
  `Unsplash.txt`).

## Invariants

- `config.js.template` requires unquoted template variables (`${TIMEOUT_MS}`,
  `${AUTO_REDIRECT}`, `${HAS_GUACAMOLE}`, `${SSH_PORT}`,
  `${HAS_JETBRAINS_GATEWAY}`) to be substituted with valid JavaScript boolean
  or numeric literals to produce syntactically valid JavaScript.
- `supportedProtocols` in `window.CWS_CONFIG` is always initialized as an
  array by splitting the comma-delimited `${SUPPORTED_PROTOCOLS}` string.
- Every component entry in `sbom.json` references a `license_id` key defined
  in the top-level `licenses` map (`Apache-2.0`, `GPL-2.0-only`,
  `GPL-3.0-only`, `BSD-2-Clause`, `MIT`, `Unsplash`), each mapping to a local
  text path under `/licenses/<license_id>.txt` (alongside `CC0-1.0.txt` in
  `public/licenses/`).

## Side Effects

- Executing the rendered `config.js.template` mutates the global browser
  `window` object by assigning `window.CWS_CONFIG`.
