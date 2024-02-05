#! /bin/sh

# Copyright 2023-2024 Google LLC
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

# https://tekton.dev/docs/installation/pipelines/
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
# https://tekton.dev/docs/installation/triggers/
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml

# https://hub.tekton.dev/tekton/task/git-clone
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.9/git-clone.yaml

kubectl apply -f $(dirname $0)/task/*.yaml
kubectl apply -f $(dirname $0)/pipeline/*.yaml
