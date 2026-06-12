#!/bin/bash

# @license
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# @fileoverview Terminal-based presentation tool using 'gum' for high-fidelity formatting.

set -u
set -o pipefail

# Visual Constants (ANSI 256-color palette)
readonly BLUE_BG="21"
readonly WHITE_FG="15"
readonly ORANGE_FG="214"
readonly HIGHLIGHT_BG="157" # Light Green
readonly HIGHLIGHT_FG="16"  # Black

# Application State
gum_theme="dark"
body_color="252" # Light Gray default
jump_to_slide=""

# Calculates luma (brightness) from RGB components using ITU-R BT.709.
# Arguments: r, g, b (0-255)
calculate_luma() {
  echo $(( ($1 * 2126 + $2 * 7152 + $3 * 722) / 10000 ))
}

# Detects terminal background color to automatically set light or dark theme.
# Uses xterm control sequences for background color querying.
detect_theme() {
  if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
    return
  fi

  local old_stty
  old_stty=$(stty -g 2>/dev/null)
  # Set terminal to non-canonical mode to read the response.
  stty -icanon -echo min 0 time 1 2>/dev/null
  printf "\e]11;?\a" > /dev/tty
  local response
  read -r -d $'\a' response < /dev/tty
  stty "${old_stty}" 2>/dev/null
  
  if [[ "${response}" =~ rgb:([0-9a-fA-F]{1,4})/([0-9a-fA-F]{1,4})/([0-9a-fA-F]{1,4}) ]]; then
    local r g b lum
    r=$(( 16#${BASH_REMATCH[1]:0:2} ))
    g=$(( 16#${BASH_REMATCH[2]:0:2} ))
    b=$(( 16#${BASH_REMATCH[3]:0:2} ))
    
    lum=$(calculate_luma "${r}" "${g}" "${b}")
    if (( lum > 127 )); then
      gum_theme="light"
      body_color="16" # Black
    fi
  fi
}

# Strips extra padding from inline code highlights.
clean_code_padding() {
  # 1. Target segments with background colors (inline code highlights).
  # 2. For tables (containing │ or ┼), move internal spaces to the end of the cell
  #    to preserve the total character count and thus column alignment.
  # 3. For regular lines, simply strip the internal spaces for a "tight" look.
  sed -E "
    /[│┼]/ {
      s/(\x1b\[[0-9;]*48;5;(${HIGHLIGHT_BG}|236|254)[0-9;]*m)[[:space:]]+([^[:space:]\x1b]+)[[:space:]]+(\x1b\[0m)/\1\3\4\x02\x02/g;
      :a; s/\x02([^│┼]*) ([│┼])/\1  \2/g; t a;
      s/\x02//g;
    };
    /[│┼]/! s/(\x1b\[[0-9;]*48;5;(${HIGHLIGHT_BG}|236|254)[0-9;]*m)[[:space:]]+([^[:space:]\x1b]+)[[:space:]]+(\x1b\[0m)/\1\3\4/g
  "
}

# Applies the core formatting pipeline to Markdown content.
# This ensures consistency across slides and helper views.
apply_formatting() {
  local use_links="${1:-false}"

  # 1. Clean up code blocks: remove existing leading spaces to take full margin control.
  awk '/^```/{code=!code; print; next} {if(code) sub(/^[[:space:]]+/, ""); print}' | \
  # 2. Protect indentation: use INDENTMARKER to prevent 'gum format' from stripping it.
  awk '{if(/^[[:space:]]+/) { sub(/^[[:space:]]+/, "INDENTMARKER"); } print}' | \
  # 3. Link handling: either protect them with markers or convert them to bold text.
  (
    if [[ "${use_links}" == "true" ]]; then
      sed -E 's/\[([^]]+)\]\(((https?|mailto):[^)]+)\)/«LNK_S»\2«LNK_M»\1«LNK_E»/g; s/<((https?|mailto):[^>]+)>/«LNK_S»\1«LNK_M»\1«LNK_E»/g; s/<([^>@]+@[^>@]+)>/«LNK_S»mailto:\1«LNK_M»\1«LNK_E»/g'
    else
      sed -E 's/\[([^]]+)\]\([^)]+\)/**\1**/g'
    fi
  ) | \
  # 4. Marker protection: prevent space-collapsing inside code blocks.
  awk '/^```/{code=!code; print; next} {if(code) printf "\001"; print}' | \
  # 5. Core rendering: use gum to format markdown.
  FORCE_COLOR=1 gum format --theme "${gum_theme}" | \
  # 6. Normalization: strip empty leading lines and fix gum formatting artifacts.
  awk 'BEGIN { leading=1 } { s=$0; gsub(/\x1b\[[0-9;]*m/, "", s); if (leading && s ~ /^[[:space:]]*$/) next; leading=0; print }' | \
  sed -E 's/^((\x1b\[[0-9;]*m)*)  /\1/' | \
  # 7. Color Injection: apply light/dark theme colors and high-contrast highlights.
  sed -E "s/38;5;(234|252)/38;5;${body_color}/g; s/48;5;(236|254)/48;5;${HIGHLIGHT_BG}/g; s/38;5;(203|39)/38;5;${HIGHLIGHT_FG}/g" | \
  # 8. Cleanup: remove link artifacts if links are disabled.
  (
    if [[ "${use_links}" == "true" ]]; then cat; else
      sed -E 's/\x1b\[[0-9;]*m \x1b\[0m\x1b\[[0-9;]*m(mailto|https?):[^[:space:]\x1b]+\x1b\[0m//g'
    fi
  ) | \
  # 9. Padding Cleanup: remove extra spaces inside code highlights.
  clean_code_padding | \
  # 10. Word Separation and Space Collapsing: move spaces outside of ANSI style sequences.
  sed -E '/\x01/!s/([[:space:]]+)((\x1b\[[0-9;]*m)*\x1b\[[0;]*m)/\2\1/g' | \
  sed -E '/\x01/!s/((\x1b\[[0-9;]*[1-9][0-9;]*m)+)([[:space:]]+)/\3\1/g' | \
  sed -E '/\x01|[│┼]/!s/[[:space:]]{2,}/ /g' | \
  sed 's/[[:space:]]*$//' | \
  # 11. Margin Application: replace markers with 2-space baseline margin.
  sed "s/\x01//g; s/INDENTMARKER/  /g" | \
  # 12. Hyperlink Reconstruction: finalize OSC 8 sequences if enabled.
  (
    if [[ "${use_links}" == "true" ]]; then
      sed -E 's/(«+)[^«»]*LNK_[^«»]*S[^«»]*(»+)/\1LNK_S\2/g; s/(«+)[^«»]*LNK_[^«»]*M[^«»]*(»+)/\1LNK_M\2/g; s/(«+)[^«»]*LNK_[^«»]*E[^«»]*(»+)/\1LNK_E\2/g' | \
      sed -E "s/«LNK_S»(([[:space:]]|\x1b\[[0-9;]*m)+)/\1«LNK_S»/g" | \
      sed -E "s/«LNK_S»([^»]*)(([[:space:]]|\x1b\[[0-9;]*m)+)«LNK_M»/\2«LNK_S»\1«LNK_M»/g" | \
      sed -E "s/«LNK_S»([^»]*)«LNK_M»(([[:space:]]|\x1b\[[0-9;]*m)+)/\2«LNK_S»\1«LNK_M»/g" | \
      sed -E "s/(([[:space:]]|\x1b\[[0-9;]*m)+)«LNK_E»/«LNK_E»\1/g" | \
      sed -E 's/«LNK_S»[[:space:]]+/«LNK_S»/g; s/[[:space:]]+«LNK_M»/«LNK_M»/g' | \
      sed -E 's/«LNK_S»([^»]+)«LNK_M»([^»]+)«LNK_E»/\x1b]8;;\1\x1b\\\2\x1b]8;;\x1b\\/g'
    else
      cat
    fi
  )
}

SUPPORTED_LANGS=("en" "es" "fr" "ru" "zh" "ar")
current_lang_idx=0

# Loads all appropriate i18n arrays into memory
load_locales() {
  local lang_code="${1:-${LANG:-en}}"
  lang_code="${lang_code:0:2}"
  
  # Find initial index
  for i in "${!SUPPORTED_LANGS[@]}"; do
    if [[ "${SUPPORTED_LANGS[$i]}" == "${lang_code}" ]]; then
      current_lang_idx=$i
      break
    fi
  done

  local locales_dir
  locales_dir="$(dirname "${BASH_SOURCE[0]}")/../locales"

  for lang in "${SUPPORTED_LANGS[@]}"; do
    if [[ -f "${locales_dir}/${lang}.sh" ]]; then
      # shellcheck disable=SC1090
      source "${locales_dir}/${lang}.sh"
    fi
  done
}

# Cycles through the supported languages
cycle_language() {
  current_lang_idx=$(( (current_lang_idx + 1) % ${#SUPPORTED_LANGS[@]} ))
}

# Translates a key by checking the current language array dynamically
t() {
  local key="$1"
  local lang="${SUPPORTED_LANGS[$current_lang_idx]}"
  local var_name="i18n_${lang}[${key}]"
  local translation="${!var_name:-}"
  
  if [[ -z "${translation}" ]]; then
    # Fallback to English
    var_name="i18n_en[${key}]"
    translation="${!var_name:-}"
    if [[ -z "${translation}" ]]; then
      translation="${key}"
    fi
  fi
  echo "${translation}"
}

# Displays a character-perfect shortcuts table using Markdown.
show_shortcuts() {
  local current="$1"
  local total="$2"
  jump_to_slide=""

  while true; do
    clear

    # 1. Header: About
    render_header "$(t about_md2tty_sh)"

    # 2. Body: About
    echo "$(t about_md2tty)
[https://github.com/GoogleCloudPlatform/cicd-foundation/presentations/md2tty](https://github.com/GoogleCloudPlatform/cicd-foundation/presentations/md2tty)" | render_body "false"

    # 3. Header: Shortcuts (with one empty line before it)
    printf "\n"
    render_header "$(t shortcuts)"

    # 4. Table: Shortcuts
    cat <<EOF | render_body "false"
| **$(t key)** | **$(t action)** | **$(t key)** | **$(t action)** |
|:---|:---|:---|:---|
| \`j\`, \`n\`, \`s\`, \`→\` | $(t next_slide) | \`k\`, \`p\`, \`w\`, \`←\` | $(t previous_slide) |
| \`PageDown\` | $(t next_slide) | \`PageUp\` | $(t previous_slide) |
| \`Home\` | $(t first_slide) | \`End\` | $(t last_slide) |
| \`1\` - \`9\` | $(t jump_to_slide) | \`t\` | $(t toggle_theme) |
| \`f\` | $(t toggle_flash) | \`l\` | $(t toggle_language) |
| \`h\`, \`?\` | $(t help) | \`q\` | $(t quit) |
EOF

    # 5. Footer
    render_footer "${current}" "${total}"

    local key
    read -rsn1 key
    case "${key}" in
      l|L) cycle_language; continue ;;
      t|T) toggle_theme; continue ;;
      [1-9])
        if [[ "${key}" -le "${total}" ]]; then
          jump_to_slide="${key}"
          return 0
        fi
        ;;
      q|Q) clear; exit 0 ;;
      *) return 0 ;;
    esac
  done
}
# Toggles the UI between light and dark themes.
toggle_theme() {
  if [[ "${gum_theme}" == "dark" ]]; then
    gum_theme="light"
    body_color="16"
  else
    gum_theme="dark"
    body_color="252"
  fi
}

# Renders the presentation footer with slide counter and key prompts.
render_footer() {
  local current="$1"
  local total="$2"
  printf "\n"
  # We substitute the Go template syntax locally since gum format does not natively parse JSON i18n
  local slide_progress
  slide_progress="$(t slide_progress)"
  slide_progress="${slide_progress//\{\{.Current\}\}/${current}}"
  slide_progress="${slide_progress//\{\{.Total\}\}/${total}}"

  FORCE_COLOR=1 gum format -t template \
    "{{ Foreground \"${ORANGE_FG}\" \"  ${slide_progress} • \" }}{{ Foreground \"${ORANGE_FG}\" (Bold \"[t]\") }}{{ Foreground \"${ORANGE_FG}\" \" $(t theme) • \" }}{{ Foreground \"${ORANGE_FG}\" (Bold \"[h]\") }}{{ Foreground \"${ORANGE_FG}\" \" $(t help) • \" }}{{ Foreground \"${ORANGE_FG}\" (Bold \"[q]\") }}{{ Foreground \"${ORANGE_FG}\" \" $(t quit)\" }}"
}

# Formats Markdown content and applies standard body indentation.
# Arguments:
#   use_links: Enable OSC 8 hyperlink sequences (default: false).
render_body() {
  local use_links="${1:-false}"
  # Strips gum's trailing empty line to allow precise vertical spacing control.
  apply_formatting "${use_links}" | sed '$d; s/^/  /'
}

# Returns a sorted list of slide files (slides/*.md, slides/*.sh).
get_slide_files() {
  local source_dir="$1"
  shopt -s nullglob
  printf '%s\n' "${source_dir}"/*.md "${source_dir}"/*.sh | sort -V
}

# Renders a stylized header banner.
render_header() {
  local header="$1"
  FORCE_COLOR=1 gum format -t template \
    "  {{ Bold (Background \"${BLUE_BG}\" (Foreground \"${WHITE_FG}\" \" ${header} \")) }}"
  printf "\n\n"
}

# Renders a Markdown slide or executes a shell script slide.
# Uses a complex multi-stage pipeline to achieve character-perfect terminal output.
#
# Arguments:
#   file: Path to the slide source.
#   current: Current slide number.
#   total: Total number of slides.
#   dump_mode: Non-interactive mode for batch rendering (default: false).
#   use_links: Enable OSC 8 hyperlink sequences (default: false).
render_slide() {
  local file="$1"
  local current="$2"
  local total="$3"
  local dump_mode="${4:-false}"
  local use_links="${5:-false}"

  if [[ "${dump_mode}" == "false" ]]; then
    clear
  fi

  # Shell slides are sourced directly for dynamic content (e.g., demos).
  if [[ "${file}" == *.sh ]]; then
    # shellcheck disable=SC1090
    source "${file}"
  else
    local first_line header body
    # Extract the first non-empty line after stripping HTML comments
    first_line=$(sed -e '/^<!--/,/-->/d' "${file}" | sed '/^[[:space:]]*$/d' | head -n 1)
    
    if [[ "${first_line}" == "# "* ]]; then
      header=$(echo "${first_line}" | sed 's/^#\+ //')
      # The body is everything except the first occurrence of the header line
      body=$(awk '!found && /^# / {found=1; next} {print}' "${file}")
    else
      header=""
      body=$(cat "${file}")
    fi

    # Render Header Banner.
    if [[ -n "${header}" ]]; then
      render_header "${header}"
    fi

    # Render Body through the formatting pipeline.
    echo "${body}" | render_body "${use_links}"
  fi

  # Render Footer.
  render_footer "${current}" "${total}"
}

# Handles user input for navigation and actions.
# Arguments:
#   idx_ref: Reference to the current slide index variable.
#   total_slides: Total number of slides.
handle_input() {
  local -n idx_ref=$1
  local total_slides=$2
  local key rest

  read -rsn1 key
  case "${key}" in
    $'\x1b') # Escape sequences (Arrows, PageUp/Down, Home/End).
      read -rsn2 -t 0.01 rest
      case "${rest}" in
        "[A"|"[D"|"[5") [[ "${rest}" == "[5" ]] && read -rsn1 -t 0.01; idx_ref=$((idx_ref - 1)) ;;
        "[B"|"[C"|"[6") [[ "${rest}" == "[6" ]] && read -rsn1 -t 0.01; idx_ref=$((idx_ref + 1)) ;;
        "[H"|"[1") [[ "${rest}" == "[1" ]] && read -rsn1 -t 0.01; idx_ref=0 ;;
        "[F"|"[4") [[ "${rest}" == "[4" ]] && read -rsn1 -t 0.01; idx_ref=$((total_slides - 1)) ;;
      esac
      ;;
    [1-9]) [[ "${key}" -le "${total_slides}" ]] && idx_ref=$((key - 1)) ;;
    \?|h|H)
      show_shortcuts "$((idx_ref + 1))" "${total_slides}"
      if [[ -n "${jump_to_slide}" ]]; then
        idx_ref=$((jump_to_slide - 1))
      fi
      ;;
    l|L) cycle_language ;;
    t|T) toggle_theme ;;
    k|p|w|K|P|W) idx_ref=$((idx_ref - 1)) ;;
    j|n|s|J|N|S|"") idx_ref=$((idx_ref + 1)) ;;
    q|Q) return 1 ;; # Signal to quit
  esac

  if [[ "${idx_ref}" -lt 0 ]]; then idx_ref=0; fi
  return 0
}

# Renders all slides in sequence for non-interactive output.
render_all_slides() {
  local use_links="$1"
  shift
  local -a files=("$@")
  local total_slides=${#files[@]}

  for ((i = 0; i < total_slides; i++)); do
    render_slide "${files[$i]}" "$((i + 1))" "${total_slides}" "true" "${use_links}"
    [[ $i -lt $((total_slides - 1)) ]] && printf "\n---\n"
  done
}

# Main Presentation Loop. Handles navigation and user input.
run_presentation() {
  local use_links="$1"
  shift
  local -a files=("$@")
  local total_slides=${#files[@]}
  local index=0

  while [[ "${index}" -ge 0 && "${index}" -lt "${total_slides}" ]]; do
    render_slide "${files[$index]}" "$((index + 1))" "${total_slides}" "false" "${use_links}"
    handle_input index "${total_slides}" || break
  done
}

# Compares two version strings (major.minor).
# Returns 0 if v1 >= v2, 1 otherwise.
version_ge() {
  local v1_major v1_minor v2_major v2_minor
  v1_major=$(echo "$1" | cut -d. -f1)
  v1_minor=$(echo "$1" | cut -d. -f2)
  v2_major=$(echo "$2" | cut -d. -f1)
  v2_minor=$(echo "$2" | cut -d. -f2)

  if (( v1_major > v2_major )); then return 0; fi
  if (( v1_major == v2_major && v1_minor >= v2_minor )); then return 0; fi
  return 1
}

# Validates that required dependencies are installed.
validate_dependencies() {
  if ! command -v gum >/dev/null 2>&1; then
    echo "Error: 'gum' is not installed. Please install it to run this presentation." >&2
    echo "See: https://github.com/charmbracelet/gum" >&2
    exit 1
  fi

  local version
  version=$(gum --version | awk '{print $3}' | sed 's/v//')
  if [[ -n "${version}" && "${version}" != "unknown" ]]; then
    if ! version_ge "${version}" "0.14"; then
      echo "Warning: 'gum' version ${version} is detected. v0.14.0 or later is recommended." >&2
    fi
  fi
}

usage() {
  echo "Usage: $0 [slide_directory] [options]"
  echo ""
  echo "Options:"
  echo "  --light      Use light theme"
  echo "  --dark       Use dark theme"
  echo "  --dump       Print all slides to stdout and exit"
  echo "  --links      Enable OSC 8 hyperlink sequences"
  echo "  --lang XX    Force a specific language (e.g. en, fr, es)"
  echo "  -h, --help   Show this help message"
  exit 1
}

# Entry point. Parses arguments and starts the presentation.
main() {
  local source_dir="slides"
  local dump_mode=false
  local use_links=false
  local force_lang=""

  # Check for help early
  for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      usage
    fi
  done

  # Determine source directory and handle flags.
  if [[ $# -gt 0 && ! "$1" == --* ]]; then
    source_dir="$1"
    shift
  fi

  if [[ ! -d "${source_dir}" ]]; then
    echo "Error: Slide directory not found: ${source_dir}" >&2
    usage
  fi

  validate_dependencies
  detect_theme

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --light) gum_theme="light"; body_color="16"; shift ;;
      --dark) gum_theme="dark"; body_color="252"; shift ;;
      --dump) dump_mode=true; shift ;;
      --links) use_links=true; shift ;;
      --lang) force_lang="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  load_locales "${force_lang}"

  local -a files
  readarray -t files < <(get_slide_files "${source_dir}")
  
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "Error: $(t error_no_slides)" >&2
    usage
  fi

  if [[ "${dump_mode}" == "true" ]]; then
    render_all_slides "${use_links}" "${files[@]}"
  else
    run_presentation "${use_links}" "${files[@]}"
  fi
  echo -e "\n"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
