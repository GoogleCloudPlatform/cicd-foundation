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

# Terminal Presentation Runner (`presentations/md2tty/bin`)

## Overview

Terminal-based Markdown presentation script (`md2tty.sh`) built on `gum format`
that provides ANSI 256-color and OSC 8 hyperlink formatting, automatic and
manual light/dark theme switching via xterm background luma detection,
multi-language localization (`en`, `es`, `fr`, `ru`, `zh`, `ar`), and
interactive keyboard shortcut navigation.

## Interface

- `BLUE_BG`, `WHITE_FG`, `ORANGE_FG`, `HIGHLIGHT_BG`, `HIGHLIGHT_FG`: Readonly
  palette configuration constants.
- `SUPPORTED_LANGS`, `gum_theme`, `body_color`, `jump_to_slide`,
  `presentation_max_height`, `current_lang_idx`: Mutable language and
  presentation state variables.
- `calculate_luma(r, g, b)`: Computes ITU-R BT.709 background luma from RGB
  values.
- `detect_theme()`: Queries terminal background color and initializes
  `gum_theme` and `body_color`.
- `clean_code_padding()`: Strips extra padding around inline code inside
  rendered tables while preserving column alignment.
- `apply_formatting([use_links])`: Formats Markdown from `stdin` via `gum
format`, `awk`, and `sed`.
- `check_and_generate_locales()`: Ensures `../locales/<lang>.sh` files are
  present and up to date with `../locales/<lang>.json`.
- `load_locales([lang_code])`: Sources generated locale Bash associative
  arrays and updates `current_lang_idx`.
- `cycle_language()`: Advances the active language across `SUPPORTED_LANGS`.
- `t(key)`: Resolves a localized string for `key` with fallback to `en` and
  the raw key.
- `show_shortcuts(current, total)`: Displays the interactive keyboard
  shortcuts modal and handles single-key input.
- `toggle_theme()`: Switches between `dark` and `light` themes.
- `render_header`, `render_body`, `render_footer`, `render_markdown(file,
[use_links])`: Slide section and Markdown rendering routines.
- `get_slide_files(source_dir)`, `render_slide(file, current, total,
[dump_mode], [use_links])`, `get_slide_height(file, [use_links])`,
  `render_all_slides(use_links, files...)`, `run_presentation(use_links,
files...)`, `handle_input(idx_ref, total_slides)`: Slide discovery, height
  calculation, full/interactive rendering, and keyboard navigation loops.
- `version_ge(v1, v2)`, `validate_dependencies()`, `usage()`,
  `main([slide_directory] [--light] [--dark] [--dump] [--links] [--lang XX]
[-h|--help])`: Dependency validation (`gum >= 0.14.0`, `jq`), CLI help, and
  main entrypoint.

## Invariants

- Runs with `set -u` and `set -o pipefail` enabled.
- Color palette constants (`BLUE_BG`, `WHITE_FG`, `ORANGE_FG`, `HIGHLIGHT_BG`,
  `HIGHLIGHT_FG`) are `readonly`.
- `gum_theme` and `body_color` are paired as `("dark", "252")` or `("light",
"16")`, with `detect_theme()` selecting light mode when ITU-R BT.709 luma
  (`(r * 2126 + g * 7152 + b * 722) / 10000`) is greater than `127`.
- `clean_code_padding()` preserves table column widths on lines containing `│`
  or `┼` by relocating stripped inline-code padding spaces to the end of the
  table cell.
- `apply_formatting()` marks lines inside fenced code blocks (` ``` `) with
  `\001` and leading non-code indentation with `INDENTMARKER` so `gum format`
  and whitespace-collapsing `sed` expressions do not strip code indentation.
- `t(key)` falls back from `i18n_<lang>[key]` to `i18n_en[key]` and finally to
  the raw `key` string.
- `show_shortcuts(current, total)` only assigns `jump_to_slide` for numeric
  keys `1`-`9` when the key value is less than or equal to `total`.

## Side Effects

- `detect_theme()` modifies terminal settings via `stty`, writes an xterm OSC
  11 query (`\e]11;?\a`) to `/dev/tty`, reads the terminal response from
  `/dev/tty`, and restores `stty` settings.
- `apply_formatting()` spawns `gum format --theme` (with `FORCE_COLOR=1`),
  `awk`, and `sed` pipeline processes to transform Markdown on `stdin` into
  ANSI-styled text on `stdout`.
- `check_and_generate_locales()` inspects `../locales/<lang>.{json,sh}`, logs
  to `stderr`, runs `node ../scripts/generate-manifest.js` when locale shell
  files are missing or older than their JSON sources, and calls `exit 1` on
  missing dependencies or generation failure.
- `load_locales()` sources `../locales/<lang>.sh` files into the current shell
  session and updates `current_lang_idx`.
- `show_shortcuts()` clears the terminal, renders the help/shortcuts UI to
  `stdout`, reads single characters from `stdin` (`read -rsn1`), mutates
  `jump_to_slide`, `current_lang_idx`, `gum_theme`, and `body_color`, and
  terminates the script with `exit 0` on `q`/`Q`.
