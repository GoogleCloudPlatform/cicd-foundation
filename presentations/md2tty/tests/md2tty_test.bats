#!/usr/bin/env bats

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

setup() {
  export PATH="$BASH_SOURCE/../bin:$PATH"
}

@test "constants are correctly defined" {
  source ./bin/md2tty.sh
  load_locales
  [ "$BLUE_BG" = "21" ]
  [ "$WHITE_FG" = "15" ]
  [ "$ORANGE_FG" = "214" ]
  [ "$HIGHLIGHT_BG" = "157" ]
  [ "$HIGHLIGHT_FG" = "16" ]
}

@test "default globals are correct" {
  source ./bin/md2tty.sh
  load_locales
  [ "$gum_theme" = "dark" ]
  [ "$body_color" = "252" ]
}

@test "render_slide function exists" {
  source ./bin/md2tty.sh
  load_locales
  run type render_slide
  [ "$status" -eq 0 ]
}

@test "detect_theme remains dark if not a TTY" {
  source ./bin/md2tty.sh
  load_locales
  detect_theme
  [ "$gum_theme" = "dark" ]
}

@test "rendering a markdown slide includes footer" {
  source ./bin/md2tty.sh
  load_locales
  echo "Slide Content" > test_slide.md
  output=$(render_slide test_slide.md 1 1 true)
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
  
  [[ "$clean_output" == *"Slide 1 of 1"* ]]
  [[ "$clean_output" == *"[t] Theme"* ]]
  
  rm test_slide.md
}

@test "rendering a markdown slide with header" {
  source ./bin/md2tty.sh
  load_locales
  echo "# My Header" > test_header.md
  echo "Body Content" >> test_header.md
  output=$(render_slide test_header.md 1 1 true)
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
  
  [[ "$clean_output" == *"My Header"* ]]
  [[ "$clean_output" == *"Body Content"* ]]
  
  rm test_header.md
}

@test "QR code preservation marker (\x01) is used and removed" {
  source ./bin/md2tty.sh
  load_locales
  printf "# QR\n\`\`\`\nQR DATA\n\`\`\`" > test_qr.md
  output=$(render_slide test_qr.md 1 1 true)
  
  [[ "$output" != *$'\x01'* ]]
  [[ "$output" == *"QR DATA"* ]]
  
  rm test_qr.md
}

@test "rendering a markdown slide with header has exactly one empty line separation" {
  source ./bin/md2tty.sh
  load_locales
  echo "# Header" > test_sep.md
  echo "Body" >> test_sep.md
  output=$(render_slide test_sep.md 1 1 true)
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
  
  header_pos=$(echo "$clean_output" | grep -n "Header" | cut -d: -f1)
  body_pos=$(echo "$clean_output" | grep -n "Body" | cut -d: -f1)
  
  [ $((body_pos - header_pos)) -eq 2 ]
  
  rm test_sep.md
}

@test "navigation jump with digits" {
  skip "Requires interactive terminal mocking"
}

@test "navigation with letters (jk, np, ws)" {
  skip "Requires interactive terminal mocking"
}

@test "shortcuts table alignment is correct" {
  source ./bin/md2tty.sh
  load_locales
  # Run show_shortcuts and simulate 'q' key press
  output=$(show_shortcuts "1" "1" <<< "q")
  
  # Strip ANSI and replace multi-bytes
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/→/./g; s/←/./g')
  
  home_row=$(echo "$clean_output" | grep "Home" | head -n 1)
  header_row=$(echo "$clean_output" | grep "Key" | head -n 1)
  help_row=$(echo "$clean_output" | grep "h, ?" | head -n 1)
  
  # Verify they have the same structure (3 bars)
  [ "$(echo "$home_row" | tr -cd '│' | wc -m)" -eq 3 ]
  [ "$(echo "$header_row" | tr -cd '│' | wc -m)" -eq 3 ]
  [ "$(echo "$help_row" | tr -cd '│' | wc -m)" -eq 3 ]
  
  # Get column positions for header
  pos1_h=$(echo "$header_row" | grep -b -o "│" | head -n 1 | cut -d: -f1)
  pos2_h=$(echo "$header_row" | grep -b -o "│" | head -n 2 | tail -n 1 | cut -d: -f1)
  pos3_h=$(echo "$header_row" | grep -b -o "│" | head -n 3 | tail -n 1 | cut -d: -f1)
  
  # Check data row
  pos1_d=$(echo "$home_row" | grep -b -o "│" | head -n 1 | cut -d: -f1)
  pos2_d=$(echo "$home_row" | grep -b -o "│" | head -n 2 | tail -n 1 | cut -d: -f1)
  pos3_d=$(echo "$home_row" | grep -b -o "│" | head -n 3 | tail -n 1 | cut -d: -f1)
  [ "$pos1_h" -eq "$pos1_d" ]
  [ "$pos2_h" -eq "$pos2_d" ]
  [ "$pos3_h" -eq "$pos3_d" ]
  
  # Check help row
  pos1_p=$(echo "$help_row" | grep -b -o "│" | head -n 1 | cut -d: -f1)
  pos2_p=$(echo "$help_row" | grep -b -o "│" | head -n 2 | tail -n 1 | cut -d: -f1)
  pos3_p=$(echo "$help_row" | grep -b -o "│" | head -n 3 | tail -n 1 | cut -d: -f1)
  [ "$pos1_h" -eq "$pos1_p" ]
  [ "$pos2_h" -eq "$pos2_p" ]
  [ "$pos3_h" -eq "$pos3_p" ]
}

@test "nested list indentation is preserved" {
  echo "1. First level" > test_indent.md
  echo "   Nested item" >> test_indent.md
  
  source ./bin/md2tty.sh
  load_locales
  output=$(render_slide test_indent.md 1 1 true)
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
  
  # Margin (2) + Marker (2) = 4 spaces.
  [[ "$clean_output" == *"    Nested item"* ]]
  
  rm test_indent.md
}

@test "language override overrides system LANG" {
  source ./bin/md2tty.sh
  export LANG="en_US.UTF-8"
  load_locales "fr"
  
  output=$(t "help")
  [ "$output" = "Aide" ]
}

@test "unsupported language fallback to english" {
  source ./bin/md2tty.sh
  load_locales "xx"
  
  output=$(t "help")
  [ "$output" = "Help" ]
}
