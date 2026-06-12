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

# 🚀 md2tty: High-Fidelity Terminal & Web Presentations

`md2tty` is a presentation suite comprising two distinct rendering engines—a Bash-based terminal tool and a Vite-based web application—that deliver character-perfect Markdown slides from a single source of truth. It uses `gum` for high-fidelity terminal rendering and `Vite` for a modern, responsive web experience.

## ✨ Features

*   **Terminal Mode**: Character-perfect grid alignment, theme detection (light/dark), and interactive navigation.
*   **Web Mode**: Responsive design with auto-scaling font sizes to fit any screen, built with Vite and Vanilla JS.
*   **Single Source of Truth**: Content is authored once in Markdown (`slides/*.md`) and rendered identically in both environments.
*   **Internationalization (i18n)**: Full support for UN languages (Arabic, Chinese, English, French, Russian, Spanish) dynamically toggled at runtime.
*   **Hyperlink Support**: Native OSC 8 sequences for terminal links and standard HTML links for the web.

## 🛠 Prerequisites

### For Terminal Mode
*   **[gum](https://github.com/charmbracelet/gum)** (v0.14.0 or later recommended): Used for formatting and UI components.
*   **bash** (v4.0 or later).

### For Web Mode
*   **Node.js** (v18 or later) & **npm**.

## 🚀 Getting Started

### Terminal Presentation
Simply run the presentation script (defaults to the `slides/` directory):
```bash
./bin/md2tty.sh
```

To present a different set of slides:
```bash
./bin/md2tty.sh path/to/your/slides/
```

To forcefully override the system language:
```bash
./bin/md2tty.sh --lang fr
```

### Web Presentation
1.  **Install dependencies**:
    ```bash
    npm install
    ```
2.  **Start development server**:
    ```bash
    npm run dev
    ```
    To use a custom slides directory for the web viewer:
    ```bash
    SLIDES_SRC=path/to/slides npm run dev
    ```
    To forcefully override the browser language or theme, append query parameters to the URL:
    ```
    http://localhost:5173/?lang=fr&theme=light
    ```
3.  **Build for production**:
    ```bash
    npm run build
    ```
    The output will be in the `dist/` directory.

## ⌨️ Shortcuts

| Key | Action |
| :--- | :--- |
| `j`, `n`, `s`, `→` | Next Slide |
| `k`, `p`, `w`, `←` | Previous Slide |
| `1`-`9` | Jump to Slide |
| `t` | Toggle Theme (Light/Dark) |
| `f` | Toggle Slide Transition Flash (Web only) |
| `l` | Toggle Language |
| `h`, `?` | Help |
| `q` | Quit |

## 🌍 Updating Translations (i18n)

The `md2tty` suite dynamically supports multiple languages across both engines.

To add or update translations:
1. Edit the respective JSON files located in `locales/*.json` (e.g. `locales/es.json`).
2. Run the manifest generator to automatically transpile the JSON files into Bash associative arrays (`locales/*.sh`) and stage them for the web viewer:
   ```bash
   npm run generate-manifest
   ```
*Note: The generated `locales/*.sh` arrays are treated as build artifacts and are excluded from version control.*

## 📂 Project Structure

*   **`slides/`**: Source Markdown files. This is your content source of truth.
*   **`src/`**: Web application logic (Vanilla JS).
*   **`styles/`**: Web application styling (CSS).
*   **`bin/`**: CLI tools and presentation scripts.
*   **`scripts/`**: Build and manifest generation scripts.
*   `tests/`: Unit and integration tests (BATS & Vitest).
*   **`docs/`**: Technical documentation, including [Requirements](docs/requirements.md) and [Design](docs/design.md).
*   `public/`: Static assets and generated staging files.

*   **`dist/`**: Minified production build output.

## 📄 License
Copyright 2026 Google LLC. Licensed under the Apache License, Version 2.0.
