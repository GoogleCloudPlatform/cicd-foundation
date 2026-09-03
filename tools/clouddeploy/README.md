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

# Cloud Deploy

## Resources

The following Cloud Deploy resources are defined using Infra-as-Code (IaC):

### Targets

- runtime solution, e.g., GKE Cluster(s) in different environments such as DEV, TEST, PROD

cf. [`deploy.tf`](../../infra/reference/deploy.tf)

### Delivery Pipelines

- a CD pipeline is required per application
  - it defines stages (for DEV, TEST, PROD) by referencing the Targets

cf. [`apps.tf`](../../infra/reference/apps.tf)
