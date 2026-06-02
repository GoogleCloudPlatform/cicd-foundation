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

# AI Agent Instructions: Preflight Dashboard

These mandates apply specifically to the Preflight layer (`examples/preflight/`).

## 1. Frontend Engineering Standards

- **SPA State Model**: The UI operates as a Single Page Application. Never bypass the atomic `state` singleton in `types.ts`.
- **Transient State Preservation**: always snapshot unsaved changes during modal navigation using the `uiTransient` mechanism.
- **Total i18n**: Never hardcode user-facing strings. Always use the `t()` helper and update all 6 UN language files.
- **Security (SRI)**: The build process automatically generates Subresource Integrity hashes. Maintain `inject-sri.cjs`.

## 2. Module-Specific Skills

- **`update-preflight`**: localized skill for hot-patching the dashboard and rendering internal docs.
  - 👉 `examples/preflight/skills/update-preflight/SKILL.md`

## 3. Global Foundation Skills

Refer to the root instructions for global tools:
👉 **[Foundation Skills](../../AGENTS.md#3-global-agent-skills-foundation)**

## 4. Mandatory Testing

Maintain **100% Vitest coverage**. Run `npm test` within `web/` before every hot-patch.

- **Routing Tests**: JSDOM v30+ enforces `window.location` immutability. All navigation testing MUST mock and assert against the abstractions in `window_utils.ts`.
- **Event Dispatching**: To prevent JSDOM `TypeError` crashes, dispatch synthesized UI events (e.g., `KeyboardEvent`) on `document.body` with `{ bubbles: true }` instead of directly on `document` or `window`.

---

👉 **[Requirements Document (PRD)](docs/requirements.md)** | 👉 **[Design Document (DD)](docs/design.md)**
