# Infrastructure Setup

- For the hands-on workshop use the [simplified](simplified/) folder.
- A reference architecture for a GCP Organization can be found in the [reference](reference/) folder.

## Prerequisites

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

Get the URL and digest of the pushed image (check the last few lines of the logs) and specify the full image URL (without a protocol) in your `terraform.tfvars` file:

```
kritis_signer_image = "gcr.io/…/kritis-signer@sha256:…"
```

#### References 🔗

- [Set up the Kritis Signer custom builder](https://cloud.google.com/binary-authorization/docs/creating-attestations-kritis#set_up_the_kritis_signer_custom_builder)


## Clean-up

You can delete all terraform-managed resources with the following command:

```sh
terraform destroy
```
