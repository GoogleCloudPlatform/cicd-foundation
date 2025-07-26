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

# This script
# - starts a workstation
# - establishes a secure tunnel with port-forwarding for SSH

if ! command -v gcloud &> /dev/null
then
    echo "Please install the gcloud CLI: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

if [ -z "$GOOGLE_CLOUD_PROJECT" ]
then
  echo "Environment variable GOOGLE_CLOUD_PROJECT not found"
  echo "=> Please enter the name of the project ID"
  echo "   hosting your Cloud Workstation: "
  read GOOGLE_CLOUD_PROJECT
fi

# web browser to use
# set an empty variable to not open the Workstation in a browser:
# BROWSER="" ws.sh
: "${BROWSER=google-chrome}"

# name of the Google Cloud region to use
: "${WS_REGION:=europe-north1}"

# name of the Cloud Workstation cluster
: "${WS_CLUSTER:=cicd-foundation}"

# name of the Cloud Workstation config
: "${WS_CONFIG:=cicd-foundation}"

# name of the Cloud Workstation instance
: "${WS_NAME:=cicd-foundation}"

# local port for SSH to use for forwarding
# set an empty variable to not establish an SSH tunnel:
# WS_LOCAL_PORT="" ws.sh
: "${WS_LOCAL_PORT=2222}"

gcloud workstations start \
  $WS_NAME \
  --cluster=$WS_CLUSTER \
  --config=$WS_CONFIG \
  --region=$WS_REGION \
  --project=$GOOGLE_CLOUD_PROJECT \

echo -n "Getting hostname: "
WS_HOST=$(gcloud workstations describe \
  $WS_NAME \
  --cluster=$WS_CLUSTER \
  --config=$WS_CONFIG \
  --region=$WS_REGION \
  --project=$GOOGLE_CLOUD_PROJECT \
| \
grep host | sed -e 's/.*: "\(.*\)".*/\1/' \
| \
sed -e 's/\"\(.*\)\"/https:\/\/\1/' \
)
if [ -n "$WS_HOST" ]
then
  echo "$WS_HOST"
else
  echo "Unable to lookup hostname!"
  exit 2
fi

if [ -n "$BROWSER" ]
then
  WS_URL="https://$WS_HOST"
  echo "Opening $WS_URL"
  $BROWSER $WS_URL &
fi

SSH_DIR="$HOME/.ssh"
if [ ! -d "$SSH_DIR" ]
then
  echo "creating $SSH_DIR"
  mkdir $SSH_DIR
fi

SSH_CONFIG=$SSH_DIR/config
SSH_HOST_NAME="ws"
grep -q "^Host ${SSH_HOST_NAME}$" $SSH_CONFIG \
|| \
( \
echo "Creating \"${SSH_HOST_NAME}\" host entry in $SSH_CONFIG" \
&& \
echo "Press Enter to continue and establish an SSH tunnel or Ctrl-C to abort." \
&& \
read \
&& \
cat >> $SSH_CONFIG << EOF
Host ${SSH_HOST_NAME}
  HostName 127.0.0.1
  Port $WS_LOCAL_PORT
  User user
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
EOF
)

if [ -n "$WS_LOCAL_PORT" ]
then
  echo "Starting SSH tunnel."
  echo "You can ssh into your Workstation with \"ssh ${SSH_HOST_NAME}\"."
  # cf. https://cloud.google.com/workstations/docs/ssh-support
  gcloud beta workstations \
    start-tcp-tunnel \
    --project=$GOOGLE_CLOUD_PROJECT \
    --region=$WS_REGION \
    --cluster=$WS_CLUSTER \
    --config=$WS_CONFIG \
    --local-host-port=:$WS_LOCAL_PORT \
    $WS_NAME \
    22
fi
