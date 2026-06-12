#!/bin/bash
file="slides/00_intro.md"
first_line=$(sed -e '/^<!--/,/-->/d' "${file}" | sed '/^[[:space:]]*$/d' | head -n 1)
if [[ "${first_line}" == "# "* ]]; then
  header=$(echo "${first_line}" | sed 's/^#\+ //')
  body=$(awk '!found && /^# / {found=1; next} {print}' "${file}")
else
  header=""
  body=$(cat "${file}")
fi
echo "HEADER: $header"
echo "BODY:"
echo "$body" | head -n 5
