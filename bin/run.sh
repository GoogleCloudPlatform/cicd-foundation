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

usage() {
  echo "Usage: $0 [options] [service]"
  echo "(only) starts one service (can be specified as positional argument)"
  echo "Options:"
  echo "  -a, --app <app>        Set the app variable"
  echo "  -d, --directory <dir>  Set the directory variable"
  echo "  -h, --help             Show this help text"
}

startService() {
  (
    cd "$ROOT_DIR/src/$1" || exit 1

    RUNNER=""
    if [ -f "pyproject.toml" ]
    then
      if grep -q 'build-backend = "poetry.core' "pyproject.toml"
      then
        poetry install
        RUNNER="poetry run"
      elif [ -f "uv.lock" ] || grep -q "hatchling.build" "pyproject.toml"
      then
        uv sync
        RUNNER="uv run"
      fi
    elif [ -f "requirements.txt" ]
    then
      #TODO (P2): use a virtual env
      pip install -q -r requirements.txt
    fi

    PROCFILE_CMD=""
    if [ -f "Procfile" ]
    then
      PROCFILE_CMD=$(sed -e 's/^[^:]*:[[:space:]]*//' < Procfile)
      #TODO (P3 optimization): minimize WORKERS=1 and THREADS=1
    fi

    if [ -z "$PROCFILE_CMD" ]
    then
      echo "Error: I do not know how to run the service $1." >&2
      echo "Please specify some Procfile." >&2
      exit 1
    fi

    echo "starting service: $1"
    if [ -n "$RUNNER" ]
    then
      $RUNNER sh -c "$PROCFILE_CMD"
    else
      sh -c "$PROCFILE_CMD"
    fi
  )
}

run() {
  for PROCFILE in "$ROOT_DIR"/src/*/Procfile
  do
    [ -e "$PROCFILE" ] || continue
    SERVICE=$(basename "$(dirname "$PROCFILE")")
    if [ -n "$1" ] && [ "$1" != "$SERVICE" ]
    then
      echo "looking to start service $1 - ignoring service $SERVICE"
      continue
    fi
    startService "$SERVICE"
    return $?
  done
  echo "Error: I did not find a service to start." >&2
  exit 1
}

. "$(dirname "$0")/common.sh"

getOpts "$@"
shift "$OPT_SHIFT"

getRootDir
readEnvs dev

run "$@"
