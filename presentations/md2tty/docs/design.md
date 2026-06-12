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

# Design Document: md2tty.js

`md2tty.js` is designed to be a "bridge" presentation tool that brings high-fidelity, interactive Markdown slides to both the developer's terminal and the modern web browser.

## 🎨 Design Philosophy

### 1. High-Fidelity Terminal Aesthetic
The project's visual identity is rooted in the terminal. Whether viewed in a shell or a browser, the slides should feel like part of a developer's toolkit. This includes:
*   Monospace typography.
*   High-contrast color palettes (ANSI 256-color inspired).
*   Block-based layouts and character-perfect alignment.

### 2. Character-Perfect Grid Rendering
In the terminal, alignment is everything. `md2tty` uses a complex multi-stage pipeline of `sed`, `awk`, and `gum` to ensure that Markdown headers, code blocks, and list items align perfectly to a virtual character grid, regardless of the content's length or styling.

### 3. Responsive Auto-Scaling (Web)
To mirror the terminal's fixed-aspect-ratio feel on the web, the browser viewer uses a custom font-scaling algorithm. It measures the "intrinsic" size of all slides at a base font size and then dynamically scales the entire UI to perfectly fit the viewport without scrolling.

### 4. Slide Transition Flash (Web)
To simulate the "clear and redraw" sensation of the terminal, the web viewer implements a 200ms "theme flash" during slide transitions. This brief visual reset reinforces the terminal-inspired feel and can be toggled via the `f` shortcut.

### 5. Unified Internationalization (i18n)
Both engines utilize a single source of truth for translations located in `locales/*.json`. 
*   **Web**: Dynamically fetches the JSON dictionaries into memory at startup.
*   **Terminal**: A build step (`npm run generate-manifest`) transpiles the JSON into native Bash associative arrays (`locales/*.sh`). This ensures the CLI remains fast and dependency-free (e.g., no `jq` requirement) at runtime.

## 🏗 Key Components

### Terminal Engine (`bin/md2tty.sh`)
A Bash-based orchestrator that:
*   Detects terminal theme and capabilities (with CLI overrides like `--light`, `--dark`, `--lang`).
*   Transforms Markdown into ANSI-rich text.
*   Handles interactive keyboard navigation, shortcuts, and provides explicit usage/help menus (`--help`).

### Web Engine (`src/`, `styles/`)
A Vanilla JavaScript and CSS application that:
*   Renders Markdown slides using `marked.js`.
*   Applies the "High-Fidelity Terminal" CSS theme.
*   Implements the auto-scaling viewport logic.
*   Resolves configuration overrides via URL search parameters (e.g., `?lang=fr&theme=light`).

### Shared Content Layer (`slides/`)
The single source of truth for all presentation data. By using standard Markdown, the content remains portable and easy to version control.

## 🎯 Target Experience
*   **Developers**: Fast, keyboard-driven presentation in the terminal.
*   **Audience**: A clean, accessible web link that looks identical to the presenter's terminal.
*   **Authors**: Write once in Markdown, present anywhere.
