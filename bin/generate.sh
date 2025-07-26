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

# generates environment specific manifest files
# using template files (envs/base/*.tmpl) and
# environmet variables (envs/*/.env)
# execute before git commit and push for CI/CD pipelines

. $(dirname $0)/common.sh
checkDependencies envsubst

usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -a                     Generate for all applications"
}

apply() {
  getRootDir
  generate
}

if [ "$1" == "-a" ]
then
  for APP in $(ls -d $(dirname $(dirname $0))/apps/*)
  do
    cd $APP
    apply
    cd -
  done
else
  apply
fi
