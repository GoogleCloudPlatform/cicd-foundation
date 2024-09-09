# Preparation 1: Create and access your Cloud Workstation 📝

## Your Cloud Workstation

Using the [Infra-as-Code](../../infra/README.md) for the [simplified](../../infra/simplified/) architecture, your Cloud Workstation has been provisioned, e.g., by a central-IT team. You can directly jump to "Access your Cloud Workstation section".  
If you are interested on how to create a workstation, you can have a look at below folded section.

<details>
<summary>Create your Cloud Workstation</summary>
If your Google Identity has been granted the [roles/workstations.workstationCreator](https://cloud.google.com/iam/docs/understanding-roles#workstations.workstationCreator) role in the project, you can create your workstation and use the provisioned [Workstation Cluster](../../infra/simplified/hub/workstations.tf#L15) and [Workstation Config](../../infra/simplified/hub/workstations.tf#L24).  

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

👉 [Download the `ws.sh` shell script](https://github.com/GoogleCloudPlatform/cicd-foundation/tree/main/bin/ws.sh), make it executable, and place it in your PATH.

<details>
<summary>Linux</summary>

```sh
mkdir -p ~/bin
curl -o ~/bin/ws.sh https://github.com/GoogleCloudPlatform/cicd-foundation/tree/main/bin/ws.sh
chmod a+x ~/bin/ws.sh
```
</details><br/>

👉 Export the following environment variables in your shell:
- `GOOGLE_CLOUD_PROJECT`: the name of the Google Cloud **project** to use
- `WS_REGION`: the name of the Google Cloud **region** to use
- `WS_CLUSTER`: the name of the Cloud Workstation **cluster**
- `WS_CONFIG`: the name of the Cloud Workstation **config**
- `WS_NAME`: the name of the Cloud Workstation **instance**

One example:
```sh
export WS_REGION=europe-north1
```

 💡 Tip: add these to your shell profile (cf. [Bash Guide](https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_03_01.html)).


👉 Executing the (downloaded) shell script
```sh
ws.sh
```
will (by default):
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

👉 Establish (if not done already) a secure tunnel to your Cloud Workstation by executing the `ws.sh` script (and keep the terminal open).  
👉 SSH into your Cloud Workstation by (simply) executing (in another terminal):
```sh
ssh ws
```

#### Transfer data

to copy a file or directory execute something like:
```sh
scp -r ws:$REMOTE_DIR/ $LOCAL_DIR/
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

👉 Press `Control`+`Shift`+`P`, enter "Remote-SSH: Connect to Host...", and select `ws`

After successful connection you will see `SSH: ws` in a green box in the bottom left corner of VSCode.
Now you can work with your Cloud Workstation from your local VSCode application!

### References 🔗

- [scp(1) - Linux man page](https://linux.die.net/man/1/scp)
- [rsync](https://rsync.samba.org/)
- [Customize Cloud Workstations container images](https://cloud.google.com/workstations/docs/customize-container-images)
