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

# a script to assist with the inner-development-loop of Cloud Run services
# not used by CI/CD pipelines

usage() {
  echo "Usage: $0 [options] <command>"
  echo "Options:"
  echo "  -a, --app <app>        Set the app variable"
  echo "  -d, --directory <dir>  Set the directory variable"
  echo "  -h, --help             Show this help text"
  echo "Commands:"
  echo "  dev                    Deploy the application in development mode"
  echo "  run                    Deploy the application in production mode"
  echo "  iam                    permit allUsers to invoke the public services"
  echo "  delete                 Delete the application"
}

getCmd() {
  case "$1" in
      # pass skaffold argument "dev", "run", or "delete" to deploy or remove
      dev | run | delete)
          COMMAND=$1
          ;;
      iam)
          COMMAND=$1
          ;;
      *)
          echo "unknown command: $1" >&2
          usage
          exit 2
          ;;
  esac
  shift
}

checkEnvs() {
  if [ -z "$PROJECT_ID" -o -z "$REGION" ]
  then
    echo "Not all environment variables have been set:" >&2
    echo "PROJECT_ID, REGION" >&2
    echo "Please specify the missing ones, e.g., in $ENV_FILE !" >&2
    exit 4
  fi
}

cloudrun() {
  if [ "$COMMAND" == "dev" ]
  then
    echo "manually execute in a different terminal:"
    echo "$0 iam"
  fi

  if [ "$COMMAND" != "iam" ]
  then
    skaffold $COMMAND \
      -f $SKAFFOLD_FILE \
      --cloud-run-project=$PROJECT_ID \
      --cloud-run-location=$REGION
  fi

  if [ "$COMMAND" != "dev" ]
  then
    applyIAM
  fi
}

applyIAM() {
  for SERVICE in $PUBLIC_SERVICES
  do
    gcloud run services add-iam-policy-binding $SERVICE --region $REGION \
        --member="allUsers" \
        --role="roles/run.invoker"
  done
}

. $(dirname $0)/common.sh

getOpts $*
getCmd $*

checkDependencies envsubst skaffold
getRootDir
readEnvs dev
checkEnvs
generate dev

cloudrun
