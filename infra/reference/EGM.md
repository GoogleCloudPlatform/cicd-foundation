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

# Reference Architecture (`reference`)

## Overview

The `infra/reference` Terraform configuration implements an opinionated
reference architecture for an enterprise multi-environment (`DEV`, `TEST`,
`PROD`) software supply chain and runtime platform on Google Cloud using
Terraform (`>= 1.9.5`) and Cloud Foundation Fabric modules
(`v32.0.0`/`v34.0.0`). It establishes a hub-and-spoke organization hierarchy
with a centralized Hub (hosting Cloud Workstations, Docker Artifact Registry,
Binary Authorization policy/attestor, Cloud KMS signing keys, and Cloud Deploy
target definitions) connected to isolated Production, Testing, and Development
spoke environments (each segmented into Shared VPC host, supplychain
build/deploy, and GKE Autopilot/Cloud Run service projects).

## Interface

- `versions.tf`: Requires Terraform `>= 1.9.5` and provider `hashicorp/google`
  `~> 5.43.1` (plus `google-beta` for Cloud Workstations resources).
- `variables.tf` (Organization, Folders, and Projects): `org_id` (number),
  `folders_create` (bool, default `false`), `folder_{hub,prod,test,dev}_id`
  (number), `projects_create` (bool, default `false`),
  `project_hub_{host,supplychain}` (string),
  `project_{prod,test,dev}_{host,supplychain,service}` (string), and
  per-project API lists `project_*_services` (list(string)).
- `variables.tf` (Networking and Locations): `region` (string, default
  `"us-central1"`), `zone` (string, default `"us-central1-a"`), `vpc_create`
  (bool, default `true`), `vpc_subnet_name` (string, default `"primary"`),
  `nat_name` (string, default `"nat"`), `vpc-hub_primary_cidr` (default
  `"10.8.0.0/22"`), `vpc-hub_psa_cidr` (default `"10.60.0.0/16"`),
  `vpc-{prod,test,dev}_psa_cidr`, `vpc-{prod,test,dev}-build_primary_cidr`,
  `vpc-{prod,test,dev}-build_psa_cidr`, and
  `cluster-{prod,test,dev}_network_config` (objects defining nodes, pods,
  services, proxy-only subnet, master, and master authorized CIDR blocks).
- `variables.tf` (IAM, Workstations, SCM, CI/CD, Security, Runtime):
  `developers` (list(string)), `sa_{ws,cb,cd,cluster}_name`, `cluster_roles`,
  `ws_{name,cluster_name,config_name,image,image_tag,idle_time,config_machine_type,config_boot_disk_size_gb,config_disable_public_ip,pool_size,nested_virtualization,pd_disk_size_gb,pd_disk_fs_type,pd_disk_type,pd_disk_reclaim_policy}`,
  `ssm_{instance_name,region}`, `github_{owner,repo}`,
  `git_branch_{trigger,trigger_regexp}`,
  `cb_pool_{name,disk_size_gb,machine_type}`,
  `build_{machine_type_default,timeout_default}`,
  `skaffold_{output,quiet,image_tag}`, `docker_image_tag`, `gcloud_image_tag`,
  `runtimes`, `stages`, `apps`, `registry_id`, `kritis_signer_image`,
  `policy_file`, `vulnz_attestor_name`,
  `kms_{key_name,keyring_name,digest_alg}`, and
  `cluster_{name,release_channel,min_version,deletion_protection}`.
- `main.tf`: Defines `module.org`, `module.folder_{hub,prod,test,dev}`,
  `module.project_hub_{host,supplychain}`,
  `module.project_{prod,test,dev}_{host,supplychain,service}`, and
  `google_project_iam_member` bindings for developers across hub and spoke
  service projects.
- `network.tf`: Defines `module.vpc-{hub,prod,test,dev}`,
  `module.fw-{hub,prod,test,dev}`, `module.peering-hub-{prod,test,dev}`,
  `module.vpc-{prod,test,dev}-build`, `module.fw-{prod,test,dev}-build`,
  `module.vpn-build-{prod,test,dev}`, and `module.vpn-{prod,test,dev}-build`.
- `workstations.tf`: Defines
  `google_workstations_workstation_cluster.cicd_foundation`, `module.sa-ws`,
  and `google_workstations_workstation_config.cicd_foundation`.
- `source.tf`: Defines `google_secure_source_manager_instance.source`,
  `google_secure_source_manager_repository.repo`, `random_id.random`,
  `google_secret_manager_secret.webhook_trigger`,
  `google_secret_manager_secret_version.webhook_trigger`,
  `data.google_iam_policy.secret_accessor`, and
  `google_secret_manager_secret_iam_policy.policy`.
- `build.tf`: Defines `module.sa-cb`,
  `google_cloudbuild_worker_pool.{prod,test,dev}`, and
  `module.docker_artifact_registry`.
- `apps.tf`: Defines `google_cloudbuild_trigger.continuous-integration`,
  `google_clouddeploy_delivery_pipeline.continuous-delivery`, and
  `google_clouddeploy_automation.promote-release` across `var.apps`.
- `deploy.tf`: Defines `module.sa-cd-{prod,test,dev}`,
  `google_clouddeploy_target.cluster-{prod,test,dev}`, and
  `google_clouddeploy_target.run-{prod,test,dev}`.
- `runtime.tf`: Defines `module.sa-cluster-{prod,test,dev}`
  (`iam-service-account`) and `module.cluster-{prod,test,dev}`
  (`gke-cluster-autopilot`).
- `security.tf`: Defines `google_binary_authorization_policy.policy`,
  `google_container_analysis_note.vulnz-attestor`,
  `google_container_analysis_note_iam_member.vulnz-attestor`,
  `google_binary_authorization_attestor.vulnz-attestor`,
  `data.google_kms_crypto_key_version.vulnz-attestor`,
  `google_kms_crypto_key_iam_member.vulnz-attestor`,
  `google_kms_crypto_key.vulnz-attestor-key`, and
  `google_kms_key_ring.keyring`.

## Invariants

- Folder and project segmentation: The hierarchy requires 4 folders under
  `organizations/${var.org_id}` (Hub, Production, Testing, Development). Hub
  contains 2 projects (`host`, `supplychain`); each environment folder
  contains 3 projects (`host`, `supplychain`, `service`). Every host project
  enables Shared VPC host mode and attaches its sibling supplychain and
  service projects as Shared VPC service projects.
- Non-transitive peering workaround via HA VPN: Spoke runtime VPCs
  (`vpc-{prod,test,dev}`) peer with `vpc-hub` via VPC Network Peering. Because
  Cloud Build worker pools use Private Service Access (Service Networking
  peering) and VPC peering is non-transitive, each spoke host project
  provisions a separate build VPC (`vpc-{prod,test,dev}-build`) with PSA
  `export_routes = true` and bridges it to its corresponding runtime VPC via
  HA VPN gateways (`vpn-build-*` <-> `vpn-*-build`) over BGP (`ASN 64514` <->
  `ASN 64513`) with custom route advertisements for the build PSA CIDR and GKE
  master CIDR.
- Cross-project Cloud Deploy execution IAM: Cloud Deploy targets live in
  `project_hub_supplychain` but execute `RENDER` and `DEPLOY` in spoke worker
  pools (`google_cloudbuild_worker_pool.{prod,test,dev}`) as spoke service
  accounts (`sa-cd-{prod,test,dev}`). This requires the Hub Cloud Deploy
  service agent to hold `roles/cloudbuild.workerPoolUser` on spoke supplychain
  projects and `roles/iam.serviceAccountUser` on `sa-cd-*`, and the Hub Cloud
  Build service agent to hold `roles/iam.serviceAccountTokenCreator` on
  `sa-cd-*`.
- Environment security gradation: `PROD` and `TEST` GKE Autopilot clusters
  enforce `enable_private_endpoint = true` and `binary_authorization = true`,
  whereas `DEV` sets `enable_private_endpoint = false` and
  `binary_authorization = false`. The Binary Authorization policy enforces
  `REQUIRE_ATTESTATION` (`vulnz-attestor`) by default (affecting `PROD`) while
  overriding `cluster-test` and `cluster-dev` to `ALWAYS_ALLOW`
  (`DRYRUN_AUDIT_LOG_ONLY`). Cloud Deploy targets require approval
  (`require_approval = true`) only for `PROD` targets (`cluster-prod`,
  `run-prod`).
- External firewall rules dependency: `fw-prod`, `fw-test`, and `fw-dev` load
  firewall definitions from local relative paths `firewall/rules` and
  `firewall/cidrs.yaml`.

## Side Effects

- Organization, folders, and projects (`main.tf`): Optionally creates or
  manages 4 Google Cloud folders (`Hub`, `Production`, `Testing`,
  `Development`) and 11 Google Cloud projects, enables per-project service
  APIs, configures Shared VPC host/service attachments, and grants IAM roles
  to developer principals and service agents.
- Networking (`network.tf`): Provisions 7 VPC networks (`hub`, `prod`, `test`,
  `dev`, and build VPCs for `prod`/`test`/`dev`) with subnets, GKE secondary
  ranges (`pods`, `services`), proxy-only subnets, and PSA ranges; 7 VPC
  firewall modules; 3 hub-to-spoke VPC peerings; and 6 HA VPN gateways (2
  tunnels each with Cloud Routers and BGP sessions) connecting build and
  runtime VPCs in each spoke.
- Cloud Workstations (`workstations.tf`): Provisions a regional
  `google_workstations_workstation_cluster` (`cicd_foundation`) in
  `project_hub_supplychain` on `vpc-hub`, a dedicated GCE service account
  (`sa-ws`), and a `google_workstations_workstation_config` with GCE
  persistent disk (`/home`) and configurable pool/machine settings.
- Source control and webhook secrets (`source.tf`): Provisions a Secure Source
  Manager instance (`source`) and repository (`repo`) in
  `project_hub_supplychain`, plus a Secret Manager secret (`webhook-trigger`)
  with IAM access for the Cloud Build service agent.
- Cloud Build, Artifact Registry, and App Pipelines (`build.tf`, `apps.tf`):
  Provisions a Cloud Build service account (`sa-cb`) in
  `project_hub_supplychain`, 3 private `google_cloudbuild_worker_pool`
  resources (`prod`, `test`, `dev`) with `no_external_ip = true` in spoke
  supplychain projects, a standard Docker Artifact Registry repository in
  `project_hub_supplychain`, and per-application Cloud Build CI triggers,
  Cloud Deploy delivery pipelines, and promotion automations.
- Cloud Deploy (`deploy.tf`): Provisions 3 execution service accounts
  (`sa-cd-{prod,test,dev}`) with folder-level `roles/container.developer` and
  hub-level Cloud Deploy roles, plus 6 `google_clouddeploy_target` resources
  in `project_hub_supplychain` (`cluster-prod`, `cluster-test`, `cluster-dev`
  for GKE internal IP targets; `run-prod`, `run-test`, `run-dev` for Cloud Run
  targets).
- Runtime clusters (`runtime.tf`): Provisions 3 node service accounts
  (`sa-cluster-{prod,test,dev}`) and 3 regional GKE Autopilot clusters
  (`cluster-{prod,test,dev}`) in the spoke service projects using Shared VPC
  subnets.
- Security, KMS, and Binary Authorization (`security.tf`): Provisions a global
  Cloud KMS key ring and asymmetric signing crypto key
  (`RSA_SIGN_PKCS1_4096_SHA512`) with `roles/cloudkms.signer` for `sa-cb`, a
  Container Analysis attestation note (`vulnz-attestor`), a Binary
  Authorization attestor bound to the KMS public key, and a Binary
  Authorization policy in `project_hub_supplychain`.
