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

## Clean-up

You can delete all terraform-managed resources with the following command:

```sh
terraform destroy
```
