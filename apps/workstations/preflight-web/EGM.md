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

# Preflight Web Application (`preflight-web`)

## Overview

Cloud Workstation (`CWS`) Custom Image Preflight web application
(`preflight-web`) written in TypeScript and bundled with Vite and Tailwind CSS.
Renders the startup preflight dashboard (`startup.html`), merges configuration
from defaults, `localStorage`, `window.CWS_CONFIG`, and URL query parameters,
polls backend health at `/readyz`, handles localization (`i18n`), displays
Software Bill of Materials (`SBOM`) and license data, provides SSH/tunnel CLI
command cards, and injects Subresource Integrity (`SRI`) hashes at build time.

## Interface

- `types.ts`: `AppConfig`, `ComponentInfo`, `LicenseInfo`, `SBOMManifest`,
  `TranslationSet`, `AppState`, `DEFAULT_CONFIG`, `state`,
  `updateState(patch)`, `resetSessionState()`, `logInfo(msg)`, and `Window`
  global interface augmentation (`window.CWS_CONFIG` and global UI/lifecycle
  handlers).
- `constants.ts`: `CONFIG_KEY`, `DEFAULT_RETRY_INTERVAL_MS`,
  `MAX_BACKOFF_INTERVAL_MS`, `PROGRESS_RING_CIRCUMFERENCE`,
  `APP_STATUS_HEADER`, `APP_STATUS_STARTING`, `NATIVE_WEB_PROTOCOLS`,
  `GUACAMOLE_PROTOCOLS`, `isNativeWebProtocol(protocol)`,
  `isGuacamoleProtocol(protocol)`, `getGuacamoleUrl(protocol)`, and
  `getProtocolFullName(proto)`.
- `window_utils.ts`: `windowUtils` (`search`, `origin`, `pathname`,
  `hostname`, `assign`, `reload`, `href`).
- `config_module.ts`: `mapStepToTimeout(step)`, `mapTimeoutToStep(val)`,
  `mapStepToRetry(step)`, `mapRetryToStep(val)`, `loadConfig()`,
  `saveConfig()`, `getCurrentUIValues()`, `applyUIValues()`,
  `updateUIFromConfig()`, `updateStatusMessage()`, `updateConfig()`,
  `resetConfig()`, `clearAllData()`, `toggleRedirect()`, `toggleRetry()`,
  `copySettingsUrl()`, and `reportBug()`.
- `health_module.ts`: `checkHealth()`, `updateVisualProgress()`,
  `updateDebugInfo()`, `handleHealthTimeout()`, `handleHealthSuccess()`,
  `startHealthChecks()`, `updateTimer()`, `manualConnect()`, and
  `startRedirect()`.
- `i18n_module.ts`: `SUPPORTED_LANGS`, `loadLocaleHashes()`,
  `fetchTranslations(lang)`, `t(key, defaultString)`, `applyTranslations()`,
  `setLanguage(lang)`, `filterLanguages()`, and `renderLanguageList(filter)`.
- `sbom_module.ts`: `loadSBOM()`, `renderLicenseList()`,
  `renderComponentDetails(name)`, `backToLicenseList()`,
  `backToComponentDetails()`, and `viewFullLicenseText(name)`.
- `shortcuts_module.ts`: `shortcuts`, `initGlobalShortcuts()`,
  `renderShortcutsList(filter)`, and `filterShortcuts()`.
- `ssh_card_module.ts`: `copyToClipboard(text, elementId)`,
  `buildSshCommand(singleLine)`, `buildTunnelCommand(port, singleLine,
localPort)`, `ensureProjectAndRegion()`, `renderSshReadyCard()`, and
  `copyPrimarySshCommand()`.
- `ui_module.ts`: `openModal(id)`, `syncRetryIntervalState()`,
  `closeModal(id)`, `closeAllModals()`, `updateDisplayData()`,
  `resetUIVisuals()`, `renderConnectionTypeList()`, and
  `initEventListeners()`.
- `startup.ts`: Application entry point that binds module functions onto
  `window` and executes `initialize()` on DOM readiness.
- `inject-sri.cjs`: Build post-processor that injects `sha384` SRI `integrity`
  attributes into `dist/startup.html` and outputs `dist/locale-hashes.json`.
- `vite.config.ts`: Vite bundler config targeting `startup.html` ->
  `dist/startup.js` with `@tailwindcss/vite`.
- **Public Static Assets**: [`./public/EGM.md`](./public/EGM.md) - Runtime
  configuration template (`config.js.template` -> `window.CWS_CONFIG`),
  placeholder `config.js`, and `sbom.json` manifest.
- **Build Scripts**: [`./scripts/EGM.md`](./scripts/EGM.md) - Fragment
  generator (`scripts/build/generate_fragments.js`) compiling
  `privacy_notice.md` into `public/privacy_notice.html`.

## Invariants

- State mutations are centralized through `updateState(patch)` on the
  singleton `state` object (`types.ts`).
- Configuration precedence in `loadConfig()` (`config_module.ts`):
  `DEFAULT_CONFIG` + browser language -> `localStorage`
  (`cws_preflight_config`, excluding sensitive/dynamic fields `hostname`,
  `clientIp`, `connectionId`, `redirectUrl`) -> `window.CWS_CONFIG` (ignoring
  unreplaced `@@SERVER_LANG@@`) -> URL query parameters.
- When `connectionId` is `SSH` and `hasGuacamole` is falsy (or
  `redirectUrl === '/startup.html'`), `autoRedirect` defaults to `false`
  unless explicitly forced via URL parameters, and health readiness renders
  the SSH command card instead of redirecting.
- Slider step mappings (`0-100`) use logarithmic scales: timeout maps to
  `1s-500s` (`mapStepToTimeout`/`mapTimeoutToStep`) and retry interval maps to
  `100ms-10000ms` (`mapStepToRetry`/`mapRetryToStep`).
- Health checks (`checkHealth()`) consider the backend healthy only when
  `/readyz?protocol=<protocol>` returns HTTP 2xx (`response.ok`) AND response
  header `x-app-status` is not `'STARTING'`, after any configured
  `simulateSec` delay has elapsed.
- Global keyboard shortcuts (`shortcuts_module.ts`) are ignored when focus is
  inside an `HTMLInputElement` or `HTMLTextAreaElement` (except `Escape`,
  which blurs the element), and when a modal is open (`state.currentModal !==
null`), only `Escape` is processed.
- Guacamole client URLs (`getGuacamoleUrl`) encode `<PROTOCOL>\0c\0default` in
  base64 with trailing `=` padding stripped: `/guacamole/#/client/<encoded>`.
- `inject-sri.cjs` skips `config.js` when injecting `sha384` integrity
  attributes into `dist/startup.html` so runtime config injection does not
  violate SRI.

## Side Effects

- DOM manipulation across `startup.html` elements, document `lang`/`dir`
  attributes (`rtl` for `ar`, `he`, `fa`, `ur`), and modal visibility.
- Global `window` object mutation in `startup.ts` (attaching 32 helper/handler
  functions) and dispatching `CustomEvent('workstation-ready')` and
  `CustomEvent('workstation-manual-connect')` on health check success and
  manual connection.
- Network HTTP `fetch` requests to `/readyz`, `/locale-hashes.json`,
  `/locales/<lang>.json`, `/sbom.json`, and `/privacy_notice.html`.
- Browser storage reads and writes to `localStorage` keys
  `cws_preflight_config`, `cws_project_id`, and `cws_region`.
- Browser navigation/redirection via `window.location` (`windowUtils`) and
  system clipboard writes via `navigator.clipboard.writeText` /
  `document.execCommand('copy')`.
- Background timers and animation loops via `setTimeout`, `clearTimeout`, and
  `requestAnimationFrame`.
- Filesystem mutations at build time in `inject-sri.cjs`: reads
  `dist/startup.html`, `public/locales/*.json`, and `public/sbom.json`, and
  writes `dist/startup.html` and `dist/locale-hashes.json`.
