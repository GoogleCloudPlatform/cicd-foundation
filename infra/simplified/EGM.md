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

# Simplified Single-Project Architecture (`simplified`)

## Overview

Root Terraform orchestration module (`infra/simplified`) for the single-project
CI/CD foundation. It instantiates a singleton shared infrastructure hub
(`module.hub` at [`./hub`](./hub/EGM.md)) and per-developer isolated team
environments (`module.team` at [`./team`](./team/EGM.md) with `for_each =
var.developers`) inside an existing Google Cloud project (`var.project_id`). It
formats developer email keys into IAM member principals and workstation
warm-pool capacity for `./hub`, derives alphabetic per-developer `team` prefixes
from email local-parts, and wires `./hub` outputs (Cloud Workstations, Secure
Source Manager, Secret Manager webhook secret, Cloud KMS/Binary Authorization
attestation, and Cloud Build/GKE service accounts) alongside
application/stage/runtime definitions into each `./team` instance.

## Interface

- `versions.tf` and `providers.tf`: Requires Terraform `>= 1.9.5`, provider
  `hashicorp/google` `~> 5.43.1`, and declares an unconfigured default
  `provider "google" {}` block.
- `variables.tf` (Required Inputs): `project_id` (`string`, existing Google
  Cloud project ID), `kritis_signer_image` (`string`, Kritis signer image
  reference), and `developers` (`map(object({ github_user = optional(string,
""), github_repo = optional(string, "cicd-foundation") }))` keyed by
  developer Google Identity email).
- `variables.tf` (Optional Region and Infrastructure Inputs): `region`
  (default `"europe-north1"`), `ssm_region` (default `"europe-west4"`), `zone`
  (default `"europe-north1-a"`), `registry_id` (default `"registry"`),
  `cluster_name` (default `"gke"`), `cluster_release_channel` (default
  `"REGULAR"`), `cluster_deletion_protection` (default `false`), and
  `cluster_min_version` (default `null`).
- `variables.tf` (Optional CI/CD and Application Inputs): `git_branch_trigger`
  (default `"main"`), `git_branch_trigger_regexp` (default `"^main$"`),
  `skaffold_image_tag` (default `"v2.13.1"`), `docker_image_tag` (default
  `"20.10.24"`), `gcloud_image_tag` (default `"490.0.0"`),
  `build_timeout_default` (default `7200`), `build_machine_type_default`
  (default `"UNSPECIFIED"`), `runtimes` (default `["gke", "cloudrun",
"workstation"]`), `stages` (default `["dev", "test", "prod"]`), and `apps`
  (`map(object({ build = optional(object({ timeout = number, machine_type =
string })), runtime = optional(string, "cloudrun"), stages =
optional(map(map(string))) }))`, defaulting to `go-hello-world`,
  `node-hello-world`, and `python-hello-world` on `gke` and `java-hello-world`
  on `cloudrun`, with `dev` replicas=1 and `test`/`prod` replicas=3).
- `main.tf` (`module "hub"`): Singleton module referencing
  [`./hub`](./hub/EGM.md), passed `project_id`, `region`, `ssm_region`,
  `kritis_signer_image`, `developers = formatlist("user:%s",
keys(var.developers))`, `ws_pool_size = length(var.developers)`,
  `registry_id`, `cluster_name`, `cluster_min_version`,
  `cluster_release_channel`, and `cluster_deletion_protection`.
- `main.tf` (`module "team"`): Iterated via `for_each = var.developers`
  referencing [`./team`](./team/EGM.md), passed `user_identity = each.key`,
  `team = join("", regexall("[a-zA-Z]", split("@", each.key)[0]))`,
  `github_owner = each.value.github_user`, `github_repo =
each.value.github_repo`, shared root variables, and cross-wired outputs from
  `module.hub`.
- Child Subdirectories:
  - [`./hub/EGM.md`](./hub/EGM.md): Shared single-project VPC, Cloud
    Workstations cluster/config, SSM instance, KMS/Binary Authorization, GKE
    Autopilot clusters (`dev`, `test`, `prod`), and Cloud Deploy targets.
  - [`./team/EGM.md`](./team/EGM.md): Per-developer Cloud Workstation
    instance, SSM repository, Docker Artifact Registry repository, Cloud
    Build triggers, and Cloud Deploy pipelines/automations.

## Invariants

- Single pre-existing project topology: `var.project_id` must reference an
  already-existing Google Cloud project; both `./hub` and `./team` set
  `project_create = false` and consolidate hub and `dev`/`test`/`prod`
  runtimes into this single project.
- Developer email key and unique alphabetic team name derivation: Keys of
  `var.developers` must be valid Google user email addresses
  (`<local>@<domain>`) because `module.hub` formats them as `user:<key>` for
  IAM bindings and `module.team` derives `team = join("", regexall("[a-zA-Z]",
split("@", each.key)[0]))`. Every developer key in `var.developers` must
  produce a non-empty, unique alphabetic local-part so team-scoped resource
  IDs (`<team>`, `<team>-<registry_id>`, `<team>-<app>`) do not collide.
- Hub-to-team dependency wiring: `module.team` directly consumes 12 outputs
  from `module.hub` (workstation cluster/config/service account, SSM
  instance/webhook secret, Kritis note/KMS key, and Cloud Build/GKE cluster
  service accounts), enforcing that `./hub` control-plane and runtime
  resources exist prior to per-developer provisioning.
- Workstation pool sizing: `module.hub` sets `ws_pool_size =
length(var.developers)`, sizing the Cloud Workstations warm pool to match
  the number of developer entries.
- Root working directory firewall files: `./hub`'s `net-vpc-firewall` module
  resolves `firewall/rules` and `firewall/cidrs.yaml` relative to the
  `infra/simplified` root working directory.
- Application stage and target alignment: Every stage in `var.stages` (`dev`,
  `test`, `prod`) must have a matching key in `var.apps[<app>].stages`, and
  `./team` implicitly binds delivery pipeline stages to `./hub`'s Cloud Deploy
  targets named `cluster-${stage}` (when `runtime == "gke"`) or `run-${stage}`
  (otherwise).

## Side Effects

- Via `module.hub` ([`./hub`](./hub/EGM.md)): Enables required Google Cloud
  APIs and binds project-level developer IAM roles in `var.project_id`;
  provisions a single VPC (`hub`, `dev`, `test`, `prod`, and `proxy` subnets,
  PSA ranges, Cloud NAT, and firewall rules); creates a shared Cloud
  Workstations cluster and configuration, a Secure Source Manager instance in
  `var.ssm_region`, and a Secret Manager webhook secret; configures a global
  Cloud KMS asymmetric signing key, Container Analysis attestation note, and
  Binary Authorization policy/attestor; and provisions dedicated service
  accounts, three GKE Autopilot clusters (`<cluster_name>-dev`,
  `<cluster_name>-test`, `<cluster_name>-prod`), and six Cloud Deploy targets
  (`cluster-dev`, `cluster-test`, `cluster-prod`, `run-dev`, `run-test`,
  `run-prod`).
- Via `module.team` ([`./team`](./team/EGM.md), per entry in
  `var.developers`): Grants `roles/containeranalysis.occurrences.editor` to
  the Cloud Build service account; provisions a developer Cloud Workstation
  (`<team>`) and IAM policy (`roles/workstations.user` for `user:<each.key>`),
  a Secure Source Manager repository (`<team>`) with
  `roles/securesourcemanager.repoWriter` binding, a Docker Artifact Registry
  repository (`<team>-<registry_id>`) with reader/writer IAM bindings, and—for
  each app in `var.apps`—a Cloud Build trigger (`<team>-<app>`), a Cloud
  Deploy delivery pipeline (`<team>-<app>`), and a Cloud Deploy release
  promotion automation (`<team>-<app>`).
