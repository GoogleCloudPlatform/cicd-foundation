#! /bin/sh

# Copyright 2023 Google LLC
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

# This script
# - initializes a login
# - starts a workstation after authentication
# - establishes a secure tunnel with port forwarding for SSH

if [ -z "$GOOGLE_CLOUD_PROJECT" ]
then
  echo "environment variable GOOGLE_CLOUD_PROJECT not found"
  echo "=> please enter the name of the project ID"
  echo "   hosting the Cloud Workstation resources: "
  read GOOGLE_CLOUD_PROJECT
fi

# name of the Google Cloud region to use
: "${WS_REGION:=europe-north1}"

# name of the Cloud Workstation cluster
: "${WS_CLUSTER:=sweets}"

# name of the Cloud Workstation config
: "${WS_CONFIG:=sweets}"

# name of the Cloud Workstation instance
: "${WS_NAME:=sweets}"

# local port for SSH to use for forwarding
: "${LOCAL_PORT:=2222}"

echo login
gcloud auth login

# echo starting workstation
gcloud workstations start \
  $WS_NAME \
  --cluster=$WS_CLUSTER \
  --config=$WS_CONFIG \
  --region=$WS_REGION \
  --project=$GOOGLE_CLOUD_PROJECT \
&& \
echo started

echo getting hostname
WS_URL=https://$(gcloud workstations describe \
  $WS_NAME \
  --cluster=$WS_CLUSTER \
  --config=$WS_CONFIG \
  --region=$WS_REGION \
  --project=$GOOGLE_CLOUD_PROJECT \
| \
#jq '.host' \
grep host | sed -e 's/.*: "\(.*\)".*/\1/' \
| \
sed -e 's/\"\(.*\)\"/https:\/\/\1/' \
)

echo "opening $WS_URL"
google-chrome $WS_URL &

if [ ! -d "$HOME/.ssh/" ]
then
  mkdir $HOME/.ssh/
fi
grep -q "^Host ws$" $HOME/.ssh/config || cat >> $HOME/.ssh/config << EOF
Host ws
  HostName 127.0.0.1
  Port 2222
  User user
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
EOF

echo starting SSH tunnel
# cf. https://cloud.google.com/workstations/docs/ssh-support
gcloud beta workstations \
  start-tcp-tunnel \
  --project=$GOOGLE_CLOUD_PROJECT \
  --region=$WS_REGION \
  --cluster=$WS_CLUSTER \
  --config=$WS_CONFIG \
  --local-host-port=:$LOCAL_PORT \
  $WS_NAME \
  22
