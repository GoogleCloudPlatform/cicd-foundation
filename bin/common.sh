#!/bin/bash

# Copyright 2023-2026 Google LLC
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

# some common functions used by scripts

getOpts() {
  OPT_SHIFT=0
  while [ $# -gt 0 ]
  do
    case "$1" in
      -a | --app)
          if [ $# -lt 2 ]
          then
            usage
            exit 1
          fi
          APP="$2"
          shift 2
          OPT_SHIFT=$((OPT_SHIFT + 2))
          ;;
      --app=*)
          APP="${1#*=}"
          shift
          OPT_SHIFT=$((OPT_SHIFT + 1))
          ;;
      -d | --directory)
          if [ $# -lt 2 ]
          then
            usage
            exit 1
          fi
          ROOT_DIR="$2"
          shift 2
          OPT_SHIFT=$((OPT_SHIFT + 2))
          ;;
      --directory=*)
          ROOT_DIR="${1#*=}"
          shift
          OPT_SHIFT=$((OPT_SHIFT + 1))
          ;;
      -h | --help)
          usage
          exit 0
          ;;
      --)
          shift
          OPT_SHIFT=$((OPT_SHIFT + 1))
          break
          ;;
      -*)
          usage
          exit 1
          ;;
      *)
          break
          ;;
    esac
  done
}

checkDependencies() {
  for DEPENDENCY in "$@"
  do
    if ! command -v "$DEPENDENCY" >/dev/null 2>&1
    then
      echo "$DEPENDENCY required but not found!" >&2
      exit 1
    fi
  done
}

resolveRepoRoot() {
  if [ -n "${BASH_VERSION:-}" ] && [ -n "${BASH_SOURCE[0]:-}" ]
  then
    COMMON_SCRIPT="${BASH_SOURCE[0]}"
  else
    COMMON_SCRIPT="$0"
  fi
  COMMON_DIR=$(dirname "$COMMON_SCRIPT")
  REPO_ROOT=$(cd "$COMMON_DIR/.." && pwd)
}

getRootDir() {
  if [ -z "$ROOT_DIR" ]
  then
    if [ -f "skaffold.yaml" ]
    then
      ROOT_DIR=$(pwd)
    else
      if [ -z "$APP" ]
      then
        echo "skaffold.yaml not found!" >&2
        echo "Please execute from the respective directory" >&2
        echo "or pass an appropriate argument!" >&2
        usage
        exit 3
      fi
      resolveRepoRoot
      ROOT_DIR="$REPO_ROOT/apps/$APP"
    fi
  elif [ -d "$ROOT_DIR" ]
  then
    ROOT_DIR=$(cd "$ROOT_DIR" && pwd)
  fi
  SKAFFOLD_FILE=$ROOT_DIR/skaffold.yaml
}

readEnv() {
  if [ -f "$1" ]
  then
    echo "reading environment file $1"
    set -a
    . "$1"
    set +a
  else
    echo "Warning: no environment file found: $1" >&2
  fi
}

readEnvs() {
  readEnv "$(dirname "$ROOT_DIR")/.env"
  for ENV in base "$@"
  do
    readEnv "$ROOT_DIR/envs/$ENV/.env"
  done
}

generateEnvManifests() {
  for TEMPLATE_FILE in "$ROOT_DIR"/envs/base/*.tmpl
  do
    [ -e "$TEMPLATE_FILE" ] || continue
    TEMPLATE_FILENAME=$(basename "${TEMPLATE_FILE%.tmpl}")
    ENVS="$*"
    if [ -z "$ENVS" ]
    then
      ENVS=$(ls -I base "$ROOT_DIR/envs/")
    fi
    for ENV in $ENVS
    do
      readEnvs "$ENV"
      set -a
      export ENV
      if [ -n "$TEAM" ]
      then
        TEAM_PREFIX="${TEAM}-"
      fi
      set +a
      GENERATED_FILE=$ROOT_DIR/envs/$ENV/$TEMPLATE_FILENAME
      echo "generating $GENERATED_FILE"
      envsubst < "$TEMPLATE_FILE" > "$GENERATED_FILE"
    done
  done
}

generateRequirementsTxt() {
  for PYPROJECT in "$ROOT_DIR"/src/*/pyproject.toml
  do
    [ -e "$PYPROJECT" ] || continue
    if grep -q "build-backend = \"poetry.core" "$PYPROJECT"
    then
      (
        cd "$(dirname "$PYPROJECT")" || exit
        poetry export -f requirements.txt --output requirements.txt
      )
    elif [ -f "$(dirname "$PYPROJECT")/uv.lock" ] || grep -q "hatchling.build" "$PYPROJECT"
    then
      (
        cd "$(dirname "$PYPROJECT")" || exit
        uv export --format requirements-txt -o requirements.txt
      )
    fi
  done
}

generate() {
  generateEnvManifests "$@"
  generateRequirementsTxt "$@"
}
