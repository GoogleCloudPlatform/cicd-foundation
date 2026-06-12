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

# md2tty: Project Requirements

This document defines the functional and technical requirements for `md2tty`, a project providing two distinct high-fidelity rendering engines that operate across terminal and web environments respectively.

## 1. Core Purpose
`md2tty` must provide a consistent, character-perfect presentation experience across both the terminal and the web, using a single set of Markdown files as the source of truth.

## 2. Platform Architecture
The project consists of two independent rendering engines that share content and interaction paradigms:
*   **Terminal Engine (`bin/md2tty.sh`)**: A Bash-based tool optimized for terminal emulators.
*   **Web Engine (`src/*.js`)**: A JavaScript-based tool optimized for modern web browsers.

### 2.1 Similarities & Shared Requirements
*   **Single Source of Truth**: Both engines must consume the same Markdown files (`slides/*.md`) without modification.
*   **High-Fidelity Rendering**: Both engines must maintain a grid-perfect, terminal-accurate design, supporting ASCII art and complex character-based content (e.g., QR codes).
*   **Navigation & Shortcuts**:
    *   Sequential navigation (Next/Previous).
    *   Direct jump to slides 1-9.
    *   Consistent keyboard shortcuts (j, k, n, p, t, l, h, q).
*   **Theming & Localization**: Support for both Light and Dark themes with visual parity, and full i18n support across all 6 UN languages toggled at runtime.
*   **Hyperlinks**: Support for clickable links (OSC 8 sequences in terminal, `<a>` tags in web).
*   **UI Elements**: A consistent layout including a stylized header banner and a footer with a progress counter and blinking cursor.

### 2.2 Differences & Platform-Specific Requirements
| Feature | Terminal Engine (`.sh`) | Web Engine (`.js`) |
| :--- | :--- | :--- |
| **Execution Environment** | Bash (v4.0+) | Web Browser / Node.js (v18+) |
| **Core Dependency** | `gum` (v0.14.0+) | `Vite`, `marked` |
| **Rendering Strategy** | ANSI escape sequences & `gum` | HTML5, CSS3, & `marked` |
| **Scaling** | Terminal-native reflowing | Dynamic `autoScale` font logic |
| **Theme Detection** | Xterm query (overridable via `--light` or `--dark`) | Defaults to dark (overridable via `?theme=`) |
| **Configuration Overrides** | CLI flags (`--lang`, `--help`, `--dump`, `--links`) | URL search parameters (`?lang=`, `?theme=`) |
| **Unique Features** | Support for executable Shell Slides (`.sh`), explicit Usage/Help output | Visual Transition Flash effect |

## 3. Functional Requirements

### 3.1 Content Management
*   **Slide Indexing**: Slides must be indexed and sorted based on their filename (convention: `slides/*.md`).
*   **Indentation**: Engines must preserve Markdown indentation levels for lists and code blocks.

### 3.2 User Interaction
*   **Help System**: Provide an on-screen help menu detailing available shortcuts.
*   **Interactive Controls**: Support both keyboard navigation and (for Web) interactive UI elements.

### 3.3 Visual Fidelity
*   **Terminal**: Maintain character-perfect grid alignment and support ANSI 256-color palettes.
*   **Web**: Implement responsive typography that auto-scales to fit the viewport dimensions while maintaining the terminal aesthetic.

## 4. Technical Requirements

### 4.1 Environment & Dependencies
*   **Terminal**:
    *   Requires `gum` for high-fidelity formatting.
    *   Must validate `gum` version and provide warnings if outdated.
*   **Web**:
    *   Requires `Vite` for development server and production bundling.
    *   Requires `marked` for client-side Markdown parsing.

### 4.2 Build & Deployment
*   **Web Manifest**: A Node.js script must generate a `slides.json` manifest and stage slide files in the `public/` directory for the Web engine.
*   **Portability**: The Terminal engine should be a self-contained script (or minimal set of scripts) runnable in most Unix-like environments.

### 4.3 Quality Assurance
*   **Testing**:
    *   **CLI**: Use BATS for integration tests of the shell script.
    *   **Web**: Use Vitest for unit and logic testing of the JS engine.
*   **Static Analysis**: ESLint for JS code and ShellCheck for shell scripts.
