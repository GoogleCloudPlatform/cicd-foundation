# Cloud Build

## Resources

The following Cloud Build resources are defined using Infra-as-Code (IaC):

### Trigger

Each application requires a trigger for instantiating a CI pipeline run, cf. [`apps.tf`](../../infra/reference/apps.tf).

For security the pipeline definition has been realized inline as part of the trigger.
Thus, the Cloud Build YAML files in this directory are not used by CI.

#### References 🔗

- [`google_cloudbuild_trigger`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudbuild_trigger) Terraform resource.
