#! /bin/bash

# Copyright 2024 Google LLC
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
  while getopts "hd:a:" FLAG
  do
    case $FLAG in
      a | app)
          APP="$OPTARG"
          ;;
      d | directory)
          ROOT_DIR="$OPTARG"
          ;;
      h | help)
          usage
          exit 0
          ;;
      *)
          usage
          exit 1
          ;;
    esac
  done
  shift $(($OPTIND - 1))
}

checkDependencies() {
  for DEPENDENCY in $*
  do
    if ! command -v $DEPENDENCY &> /dev/null
    then
      echo "$DEPENDENCY required but not found!"
      exit 1
    fi
  done
}

getRootDir() {
  if [ -z "$ROOT_DIR" ]
  then
    if [ -f "skaffold.yaml" ]
    then
      ROOT_DIR="$(pwd)"
    else
      if [ -z "$APP" ]
      then
        echo "skaffold.yaml not found!" >&2
        echo "Please execute from the respective directory" >&2
        echo "or pass an appropriate argument!" >&2
        usage
        exit 3
      fi
      ROOT_DIR="$(dirname$(dirname $0))/apps/$APP"
    fi
  fi
  SKAFFOLD_FILE=$ROOT_DIR/skaffold.yaml
}

readEnv() {
  if [ -f "$1" ]
  then
    echo "reading environment file $1"
    set -a
    . $1
    set +a
  else
    echo "Warning: no environment file found: $1" >&2
  fi
}

readEnvs() {
  readEnv "$(dirname $ROOT_DIR)/.env"
  for ENV in base $*
  do
    readEnv "$ROOT_DIR/envs/$ENV/.env"
  done
}

generateEnvManifests() {
  for TEMPLATE_FILE in $(ls $ROOT_DIR/envs/base/*.tmpl 2>/dev/null)
  do
    TEMPLATE_FILENAME=$(basename ${TEMPLATE_FILE%.tmpl})
    ENV_DIRS="$*"
    if [ -z "$ENV_DIRS" ]
    then
      ENVS=$(ls -I base $ROOT_DIR/envs/)
    fi
    for ENV in $ENVS
    do
      readEnvs $ENV
      set -a
      ENV=$ENV
      if [ -n "$TEAM" ]
      then
        TEAM_PREFIX="${TEAM}-"
      fi
      set +a
      GENERATED_FILE=$ROOT_DIR/envs/$ENV/$TEMPLATE_FILENAME
      echo "generating $GENERATED_FILE"
      envsubst < $TEMPLATE_FILE > $GENERATED_FILE
    done
  done
}

generateRequirementsTxt() {
  for PYPROJECT in $(ls $ROOT_DIR/src/*/pyproject.toml 2>/dev/null)
  do
    if grep -q "build-backend = \"poetry.core" $PYPROJECT
    then
      cd $(dirname $PYPROJECT)
      poetry export -f requirements.txt --output requirements.txt
      cd -
    fi
  done
}

generate() {
  generateEnvManifests $*
  generateRequirementsTxt $*
}
