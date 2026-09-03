#! /bin/sh

# Copyright 2023-2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

usage() {
  echo "Usage: $(basename "$0") [--help] [--path-to-modules <path>]"
  echo "  --help: Show this help message."
  echo "  --path-to-modules: Specify the path to the directory containing Terraform modules."
  echo "                     Defaults to $(dirname "$(cd "$(dirname "$0")" && pwd)")/infra/modules"
}

MODULES_DIR="$(dirname "$(cd "$(dirname "$0")" && pwd)")/infra/modules"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --help)
      usage
      exit 0
      ;;
    --path-to-modules)
      if [[ -n "$2" ]]; then
        MODULES_DIR="$2"
        shift
      else
        echo "Error: --path-to-modules requires an argument." >&2
        usage
        exit 1
      fi
      ;;
    *)
      echo "Error: Unknown option '$1'." >&2
      usage
      exit 1
      ;;
  esac
  shift
done

OUTPUT_TEMPLATE=$(cat <<'EOF'
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
{{ .Content }}

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
EOF
)

for MODULE in $(find "$MODULES_DIR" -maxdepth 1 -type d -o -type l | grep -v "$MODULES_DIR$")
do
  cd $MODULE \
  && \
  terraform-docs markdown \
      --output-template "${OUTPUT_TEMPLATE}" \
      --show inputs \
      --show outputs \
      --output-file=README.md \
      . \
  && \
  cd - > /dev/null
done
