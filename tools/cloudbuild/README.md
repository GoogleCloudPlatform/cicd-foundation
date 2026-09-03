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

# Cloud Build

## Resources

The following Cloud Build resources are defined using Infra-as-Code (IaC):

### Trigger

Each application requires a trigger for instantiating a CI pipeline run, cf. [`apps.tf`](../../infra/reference/apps.tf).

For security the pipeline definition has been realized inline as part of the trigger.
Thus, (example) Cloud Build YAML(s) hosted in this repository are not used by CI.

#### References 🔗

- [`google_cloudbuild_trigger`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudbuild_trigger) Terraform resource.
