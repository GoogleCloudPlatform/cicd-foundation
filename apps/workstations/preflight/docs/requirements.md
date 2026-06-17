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

# Product Requirements Document: Custom Image Preflight

## 1. Problem Statement

Google Cloud Workstations block external traffic until internal system services are ready. During this "boot-up" phase, users typically experience a **"Hard Silence"**—a blank screen or timeout—without any visual feedback on the workstation's status. This results in high user anxiety and a perceived lack of system reliability.

The **Preflight Layer** must bridge this gap by providing an immediate, high-quality loading experience that manages technical handoffs and status reporting.

## 2. User Personas

- **The Developer**: Needs immediate confirmation that the workstation is starting and wants to know exactly when they can begin working.
- **The Platform SRE**: Needs a configurable, secure loading layer that doesn't add significant overhead or security vulnerabilities to the custom image.

## 3. Functional Requirements

### 3.1. Interception & Proxying

- **R1.1**: Intercept early traffic attempts to backend remote desktop protocols (RDP, VNC, SSH).
- **R1.2**: Support multi-protocol handoff to Apache Guacamole.

### 3.2. Ephemeral Credential Management

- **R2.1**: Generate high-entropy ephemeral passwords on every container boot.
- **R2.2**: Seamlessly inject credentials into Guacamole and Nginx without user intervention.

### 3.3. Interactive Dashboard

- **R3.1**: Display real-time health telemetry from the backend services.
- **R3.2**: Provide a "Technical Debug" overlay for advanced troubleshooting.
- **R3.3**: Support session re-simulation (resetting timers/polling) without a full page reload.

### 3.4. Configuration Overrides

- **R4.1**: Support persistent user settings (Language, Debug Mode) via LocalStorage.
- **R4.2**: Support ephemeral developer overrides via URL parameters (e.g., `?lang=ar&debug=true&simulateDelay=15`).

### 3.5. Optional UI Distribution

- **R5.1**: Support completely bypassing the preflight UI generation at build time, falling back to a direct Guacamole connection.
- **R5.2**: Support fetching the preflight UI source from an external git repository via build arguments (`PREFLIGHT_WEB_REPO`, `PREFLIGHT_WEB_DIR`).

## 4. Non-Functional Requirements

### 4.1. Performance & "Cinematic" Reveal

- **N1.1**: The UI must render its primary layout within **1500ms** of initial load.
- **N1.2**: Minimal bundle size by using Vanilla TypeScript and avoiding heavy frameworks.

### 4.2. Internationalization (i18n)

- **N2.1**: Full support for the **6 UN Languages** (Arabic, Chinese, English, French, Russian, Spanish).
- **N2.2**: Strict **Resolution Hierarchy**:
  1. URL Parameter (`?lang=XX`)
  2. Server Metadata (`window.CWS_CONFIG.serverLang`)
  3. Local Storage
  4. Browser Preference (`navigator.language`)
  5. System Fallback (`en`)

### 4.3. Accessibility (WCAG Compliance)

- **N3.1**: Interactive elements must have clear, high-contrast focus states (`focus-ring`).
- **N3.2**: Dynamic regions (Status, Timer) must utilize `aria-live` for screen reader announcements.
- **N3.3**: Support aliased keyboard triggers (e.g., `H` and `?` for Help).
- **N3.4**: Sticky Modal Architecture: Modals must maintain visible actions (Save/Reset) across all viewports.

### 4.4. Security

- **N4.1**: Enforce **Subresource Integrity (SRI)** for all JS and localization assets.
- **N4.2**: Zero-external-dependency documentation: Pre-render Markdown into HTML fragments during build for offline availability.

### 4.5. Reliability

- **N5.1**: Maintain **100% Vitest coverage** for all frontend components.
- **N5.2**: Resilient health polling with phased backoff (Nominal -> Exponential Backoff after threshold).

## 5. Constraints & Sliders

- **Timeout Threshold**: Logarithmic mapping for user control (1s to 500s).
- **Retry Interval**: Precision control (100ms to 10s).
