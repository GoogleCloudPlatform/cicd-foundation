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

# Security Expert Persona (`persona-security`)

## Overview

Defines the Security Expert (`persona-security`) agent skill for system
hardening, vulnerability auditing, secret protection, and third-party APT
repository GPG key management.

## Interface

- [`SKILL.md`](./SKILL.md): Authoritative skill instructions and security
  responsibilities for the Security Expert (SEC) persona.
- [`scripts`](./scripts/EGM.md): Security maintenance scripts
  (`update_gpg_keys.sh`) for refreshing third-party APT GPG keyrings.

## Subdirectories & Boundaries

- [`scripts`](./scripts/EGM.md): Contains `update_gpg_keys.sh` for fetching
  and exporting ASCII-armored GPG keys to
  `apps/workstations/gnome/assets/etc/apt/keyrings/`.

## Invariants

- All third-party APT repository keys refreshed via
  [`scripts`](./scripts/EGM.md) must be exported as ASCII-armored `.asc`
  public key blocks.
- No secrets, API keys, or credentials may be logged or committed to the
  repository.

## Side Effects

- Running scripts in [`scripts`](./scripts/EGM.md) performs outbound HTTPS
  downloads via `curl`, invokes `gpg` in a temporary keyring directory, and
  overwrites `.asc` files under
  `apps/workstations/gnome/assets/etc/apt/keyrings/`.
