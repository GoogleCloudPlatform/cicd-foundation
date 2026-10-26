<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Preparation 1: Create and access your Cloud Workstation 📝

## Your Cloud Workstation

Using the [Infra-as-Code](../../../infra/README.md) for the [simplified](../../../infra/simplified/) architecture, your Cloud Workstation has been provisioned, e.g., by a central-IT team. You can directly jump to "Access your Cloud Workstation section".  
If you are interested on how to create a workstation, you can have a look at below folded section.

<details>
<summary>Create your Cloud Workstation</summary>
If your Google Identity has been granted the [roles/workstations.workstationCreator](https://cloud.google.com/iam/docs/understanding-roles#workstations.workstationCreator) role in the project, you can create your workstation and use the provisioned [Workstation Cluster](../../../infra/simplified/hub/workstations.tf#L15) and [Workstation Config](../../../infra/simplified/hub/workstations.tf#L24).

<br/>
Create your workstation with either of the methods below (gcloud, Terraform, Google Cloud Console):

### gcloud

[`gcloud workstations create`](https://cloud.google.com/sdk/gcloud/reference/workstations/create)

### Terraform

Use the [`google_workstations_workstation`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/workstations_workstation) Terraform resource.

### Google Cloud Console

[Open the Workstations page in the Google Cloud Console](https://console.cloud.google.com/workstations/list)

⚠️ Make sure to select the right GCP project.

- Create a new Workstation by using one of the existing Workstation Configuration.

### References 🔗

- [Create and launch a workstation](https://cloud.google.com/workstations/docs/create-workstation)
</details>

## Access your Cloud Workstation

Access your workstation with either of the methods below (Google Cloud Console, via a script, in VSCode):

### Google Cloud Console

In [Google Cloud Console](https://console.cloud.google.com/workstations/list):

- Start your Workstation.
- Launch your running Workstation in the browser.

### Using a Script

👉 [Download the `manage_workstation.sh` shell script](https://github.com/GoogleCloudPlatform/cicd-foundation/blob/main/skills/persona-sre/scripts/manage_workstation.sh), make it executable, and place it in your PATH.

<details>
<summary>Linux</summary>

```sh
mkdir -p ~/bin
curl -o ~/bin/manage_workstation.sh https://raw.githubusercontent.com/GoogleCloudPlatform/cicd-foundation/main/skills/persona-sre/scripts/manage_workstation.sh
chmod a+x ~/bin/manage_workstation.sh
```

</details><br/>

👉 Export the following required environment variables in your shell (or pass `--project`, `--region`, `--cluster`, `--config`, and `[WORKSTATION]` as CLI flags):

- `GOOGLE_CLOUD_PROJECT`: the ID of the Google Cloud **project** hosting the workstation
- `CWS_REGION`: the name of the Google Cloud **region** to use
- `CWS_CLUSTER`: the name of the Cloud Workstation **cluster**
- `CWS_CONFIG`: the name of the Cloud Workstation **config**
- `CWS_NAME`: the name of the Cloud Workstation **instance**

Optional environment variables:

- `CWS_LOCAL_PORT`: local SSH forwarding port (default: `2222`, or `--local-port`)
- `BROWSER`: browser binary launched when `--browser` is passed (default: `google-chrome`)

Example:

```sh
export GOOGLE_CLOUD_PROJECT="my-gcp-project"
export CWS_REGION="europe-north1"
export CWS_CLUSTER="cicd-foundation"
export CWS_CONFIG="cicd-foundation"
export CWS_NAME="my-workstation"
```

💡 Tip: add these to your shell profile (cf. [Bash Guide](https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_03_01.html)).

👉 Executing the (downloaded) shell script

```sh
manage_workstation.sh tunnel --browser
```

will:

1. start the Cloud Workstation (if not already running) and wait until it reaches `STATE_RUNNING`
1. open the Cloud Workstation in a web browser
1. add below entry in `~/.ssh/config` if not found
1. establish a secure tunnel with port forwarding for SSH (see below)

#### `~/.ssh/config`

This entry will be added to your ssh config file if not found:

```
Host cws
  HostName 127.0.0.1
  Port 2222
  User user
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
```

- `StrictHostKeyChecking` is disabled as the instance will not have a persistent SSH key; apart, also the IP is not fixed.
- For thes reasons also the `UserKnownHostsFile` is irrelevant.

### Secure Shell (SSH)

👉 Establish (if not done already) a secure tunnel to your Cloud Workstation by executing `manage_workstation.sh tunnel --browser` (and keep the terminal open).  
👉 SSH into your Cloud Workstation by (simply) executing (in another terminal):

```sh
ssh cws
```

#### Transfer data

to copy a file or directory execute something like:

```sh
scp -r cws:$REMOTE_DIR/ $LOCAL_DIR/
```

If you need / prefer to use `rsync` for transfer, install the package in your Workstation - or make sure the container image (see below link for customizing the container images) contains the package:

```sh
sudo apt-get install -y rsync
```

### Visual Studio Code (VSCode)

#### Prerequisite

In your local VSCode, install the [Remote Development](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack) extension pack:

👉 Press `Control`+`P` and enter `ext install ms-vscode-remote.vscode-remote-extensionpack`

#### Remote-SSH

👉 If you have not yet establish a secure tunnel via SSH (see above) do so now.

👉 Press `Control`+`Shift`+`P`, enter "Remote-SSH: Connect to Host...", and select `cws`

After successful connection you will see `SSH: cws` in a green box in the bottom left corner of VSCode.
Now you can work with your Cloud Workstation from your local VSCode application!

### References 🔗

- [scp(1) - Linux man page](https://linux.die.net/man/1/scp)
- [rsync](https://rsync.samba.org/)
- [Customize Cloud Workstations container images](https://cloud.google.com/workstations/docs/customize-container-images)
