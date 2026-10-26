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

# Legal Enforcer Embedded Locales (`internal/locales`)

## Overview

Embeds localized JSON message catalogs (`ar.json`, `en.json`, `es.json`,
`fr.json`, `ru.json`, `zh.json`) into the Go binary for use by the
`license_enforcer` CLI tool.

## Interface

- `var Content embed.FS`: Embedded filesystem populated via `//go:embed
*.json` containing localization JSON files for the 6 official United Nations
  languages (`ar`, `en`, `es`, `fr`, `ru`, `zh`).

## Invariants

- Each embedded locale JSON file is a JSON array of objects with `"id"` and
  `"translation"` keys defining message templates sorted alphabetically by
  `"id"` for `license_enforcer` CLI status, error, summary, and usage strings
  (including template variables `{{.License}}`, `{{.Path}}`, `{{.Holder}}`,
  `{{.Error}}`, `{{.Count}}`, `{{.FoundLicense}}`, and
  `{{.AcceptableLicenses}}`).

## Side Effects

- None at runtime; embeds matching `*.json` files from the directory into the
  binary at compile time via `//go:embed`.
