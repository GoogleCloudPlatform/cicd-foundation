#! /bin/bash

# Copyright 2024 Google LLC
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
  echo "Usage: $0 [service]"
  echo "(only) starts one service (can be specified as first argument)"
}

startService() {
  cd $ROOT_DIR/src/$1

  if [ -f "pyproject.toml" ]
  then
    poetry install
    COMMAND="poetry run"
  elif [ -f "requirements.txt" ]
  then
    #TODO (P2): use a virtual env
    pip install -q -r requirements.txt
  fi

  if [ -f "Procfile" ]
  then
    COMMAND=$(sed -e's/.*: //' < Procfile)
    #TODO (P3 optimization): minimize WORKERS=1 and THREADS=1
  fi

  if [ -z "$COMMAND" ]
  then
    echo "Error: I do not know how to run the service $1."
    echo "Please specify some Procfile."
    cd -
    exit 1
  fi
  echo "starting service: $1"
  echo $COMMAND | sh
  cd -
}

run() {
  for PROCFILE in $(ls $ROOT_DIR/src/*/Procfile 2>/dev/null)
  do
    SERVICE=$(basename $(dirname $PROCFILE))
    if [ -n "$1" -a "$1" != "$SERVICE" ]
    then
      echo "looking to start service $1 - ignoring service $SERVICE"
      continue
    fi
    startService $SERVICE
    return
  done
  echo "Error: I did not find a service to start." >&2
}

. $(dirname $0)/common.sh
getRootDir
readEnvs dev

run
