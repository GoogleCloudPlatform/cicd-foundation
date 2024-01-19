# Preparation 1: Create and Access your Cloud Workstation 📝

## Create your Cloud Workstation

### Prerequisites

Day 0: A Workstation Cluster ([`google_workstations_workstation_cluster`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/workstations_workstation_cluster)) and Workstation Config ([`google_workstations_workstation_config`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/workstations_workstation_config)) have already been created, e.g., by a central-IT team and your Google Identity has been granted the [`roles/workstations.workstationCreator`](https://cloud.google.com/iam/docs/understanding-roles#workstations.workstationCreator) permissions in the project.

### Terraform

Use the [`google_workstations_workstation`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/workstations_workstation) Terraform resource.

### gcloud

[`gcloud workstations create`](https://cloud.google.com/sdk/gcloud/reference/workstations/create)

## Access your Cloud Workstation

👉 [Download the `ws.sh` shell script](https://github.com/GoogleCloudPlatform/cicd-jumpstart/tree/main/bin/ws.sh) and place it in your PATH.

👉 Export the following environment variables in your shell:
- `WS_REGION`: the name of the Google Cloud **region** to use
- `WS_CLUSTER`: the name of the Cloud Workstation **cluster**
- `WS_CONFIG`: the name of the Cloud Workstation **config**
- `WS_NAME`: the name of the Cloud Workstation **instance**

One example:
```sh
export WS_REGION=europe-north1
```

 💡 Tip: add these to your shell profile (cf. [Bash Guide](https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_03_01.html)).


### Web Browser

👉 Executing the (downloaded) shell script
```sh
ws.sh
```
will:
1. initialize a `gcloud auth login`
1. start the Cloud Workstation after authentication
1. open the Cloud Workstation in a web browser 
1. add below entry in `~/.ssh/config` if not found
1. establish a secure tunnel with port forwarding for SSH (see below)

#### `~/.ssh/config`

This entry will be added to your ssh config file if not found:
```
Host ws
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

👉 Establish a secure tunnel to your Cloud Workstation by executing the `ws.sh` script (if not done already).  
👉 SSH into your Cloud Workstation by (simply) executing:

```sh
ssh ws
```

### Visual Studio Code (VSCode)

#### Prerequisite

In your local VSCode, install the [Remote Development](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack) extension pack:

👉 Press `Control`+`P` and enter `ext install ms-vscode-remote.vscode-remote-extensionpack`

#### Remote-SSH

👉 If you have not yet establish a secure tunnel via SSH (see above) do so now.

👉 Press `Control`+`Shift`+`P`, enter "Remote-SSH: Connect to Host...", and select `ws`

After successful connection you will see `SSH: ws` in a green box in the bottom left corner of VSCode.
Now you can work with your Cloud Workstation from your local VSCode application!

#### Transfer data

to copy a file or directory execute something like:
```sh
scp -r ws:$REMOTE_DIR/ $LOCAL_DIR/
```

If you need / prefer to use `rsync` for transfer, install the package in your Workstation - or make sure the container image (see below link for customizing the container images) contains the package:
```sh
sudo apt-get install -y rsync
```

### References 🔗

- [scp(1) - Linux man page](https://linux.die.net/man/1/scp)
- [rsync](https://rsync.samba.org/)
- [Customize Cloud Workstations container images](https://cloud.google.com/workstations/docs/customize-container-images)
