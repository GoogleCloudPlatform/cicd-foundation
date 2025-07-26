# Infrastructure Setup

- For the hands-on workshop use the [simplified](simplified/) folder.
- A reference architecture for a GCP Organization can be found in the [reference](reference/) folder.

## Prerequisites

### GCP Project

For the simplified architecture a single GCP project is required that can be placed in a sandbox environment and deleted after the hands-on workshop.

### List of Participants

For each participant list their Google Identity in the `developers` map in `terraform.tfvars` (cf. [`terraform.tfvars.example`](./simplified/terraform.tfvars.example)).
This will provision respective resources (such as a Cloud Workstation) for them and grant required permissions.

⚠️ In case GitHub shall be used to trigger the Continuous Integration pipeline, the users need to establish a connection to their GitHub repository before the `google_cloudbuild_trigger` Terraform resource can be created, cf. [this comment](./simplified/team/apps.tf#L15).

In the absence of a `github_user`, a repository in the shared Secure Source Manager instance will be provisioned.
In the hands-on workshop the participants will be able to check out and work with a repository from GitHub using their Cloud Workstation and GitHub credentials but the CI/CD automation will be based on the (private) repositories where we will be pushing the cloned code to and where changes will be conducted.

### Cloud Storage Bucket

This is for storing the Terraform state file.  
It is recommended to create / use a bucket in a (central) "seed" project that is used for infrastructure automation.  

👉 Change `YOUR_BUCKET` in `backend.tf.example` and rename to `backend.tf`.

#### References 🔗

- [Create a new bucket](https://cloud.google.com/storage/docs/creating-buckets#create_a_new_bucket)

## Provision through IaC

👉 First authenticate:

```sh
gcloud auth application-default login
```

👉 Then execute Terraform:

```sh
terraform init
terraform apply
```

## Deploy Kritis for Binary Authorization

First, clone the Kritis repository:

```sh
git clone https://github.com/grafeas/kritis.git
cd kritis
```

Next, set the GCP project to where Cloud Build will be running (cf. `project_prod_supplychain` variable in the reference architecture of the single `project_id` in the simplified architecture).

```sh
gcloud config set project $GOOGLE_CLOUD_PROJECT
```

Build and register Kritis Signer custom builder:

```sh
gcloud builds submit . --config deploy/kritis-signer/cloudbuild.yaml
```

Get the URL and digest of the pushed image (check the last few lines of the logs) and define the `kritis_signer_image` variable in your `terraform.tfvars` file by specifing the full image URL (without a protocol). This should look like this:

```
kritis_signer_image = "gcr.io/…/kritis-signer@sha256:…"
```

Re-run terraform:
```
terraform apply
```

#### References 🔗

- [Set up the Kritis Signer custom builder](https://cloud.google.com/binary-authorization/docs/creating-attestations-kritis#set_up_the_kritis_signer_custom_builder)


## Clean-up

You can delete all terraform-managed resources with the following command:

```sh
terraform destroy
```
