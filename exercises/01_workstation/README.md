# Preparation 1: Create and Access your Cloud Workstation 📝

## Create your Cloud Workstation

### Prerequisites

Day 0: A Workstation Cluster ([`google_workstations_workstation_cluster`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/workstations_workstation_cluster)) and Workstation Config ([`google_workstations_workstation_config`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/workstations_workstation_config)) have already been created, e.g., by a central-IT team and your Google Identity has been granted the `roles/workstations.workstationCreator` permissions in the project.

### Terraform

Use the [`google_workstations_workstation`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/workstations_workstation) Terraform resource.

### gcloud

[`gcloud workstations create`](https://cloud.google.com/sdk/gcloud/reference/workstations/create)


## Access your Cloud Workstation

### Web Browser

👉 Executing the shell script
```sh
./ws.sh
```
will:
1. initialize a login
1. start the Cloud Workstation after authentication
1. open the Cloud Workstation in a web browser 
1. add below entry in `~/.ssh/config` if not found
1. establish a secure tunnel with port forwarding for SSH (see below)

#### `~/.ssh/config`
```
Host ws
  HostName 127.0.0.1
  Port 2222
  User user
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
```
- `StrictHostKeyChecking` is disabled as the instance will not have a persistent SSH key and also IP.  
- For this reason also the `UserKnownHostsFile` is irrelevant.

### Secure Shell

👉 Establish a secure tunnel to your Cloud Workstation by executing the `ws.sh` script (if not done already).  
👉 SSH into your Cloud Workstation by (simply) executing:

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

### References 🔗

- [scp(1) - Linux man page](https://linux.die.net/man/1/scp)
- [rsync](https://rsync.samba.org/)
- [Customize Cloud Workstations container images](https://cloud.google.com/workstations/docs/customize-container-images)
