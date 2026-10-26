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

# Simplified Hub Module (`hub`)

## Overview

The `infra/simplified/hub` Terraform module provisions the foundational shared
CI/CD, networking, security/attestation, and runtime infrastructure within a
single existing Google Cloud project. It sets up a central VPC with dedicated
subnets (`hub`, `dev`, `test`, `prod`, plus a proxy-only subnet and Private
Service Access range), Cloud NAT, and VPC firewall rules; provisions developer
tooling and CI/CD control-plane resources including a Cloud Workstations cluster
and configuration, a Secure Source Manager (SSM) instance, a Cloud Build service
account and webhook secret, and environment-specific Cloud Deploy targets and
service accounts; configures Binary Authorization with a Container Analysis
attestation note and asymmetric Cloud KMS signing key; and provisions three GKE
Autopilot runtime clusters (`dev`, `test`, `prod`).

## Interface

- Input variables (`variables.tf`): Project and API configuration
  (`project_id`, `region`, `project_services`, `developers`), VPC and
  networking (`vpc_create`, `vpc-hub_primary_cidr`, `vpc-hub_psa_cidr`,
  `proxy_only_subnet_cidr_block`, `nat_name`, `cluster-dev_network_config`,
  `cluster-test_network_config`, `cluster-prod_network_config`), Cloud
  Workstations (`ws_cluster_name`, `ws_config_name`, `sa_ws_name`,
  `ws_pool_size`, `ws_idle_time`, `ws_config_machine_type`,
  `ws_config_boot_disk_size_gb`, `ws_nested_virtualization`,
  `ws_pd_disk_size_gb`, `ws_pd_disk_fs_type`, `ws_pd_disk_type`,
  `ws_pd_disk_reclaim_policy`, `ws_config_disable_public_ip`), Secure Source
  Manager (`ssm_instance_name`, `ssm_region`), CI/CD and Artifact Registry
  (`sa_cb_name`, `sa_cd_name`, `registry_id`), Binary Authorization and KMS
  (`kritis_signer_image`, `vulnz_attestor_name`, `kms_key_name`,
  `kms_keyring_name`, `kms_digest_alg`), and GKE clusters (`cluster_name`,
  `cluster_deletion_protection`, `cluster_min_version`,
  `cluster_release_channel`, `sa_cluster_name`, `cluster_roles`).
- Outputs (`outputs.tf`): Cloud Workstations identifiers (`ws_cluster_id`,
  `ws_config_id`, `workstations_sa_email`), SCM and webhook secret
  (`ssm_instance_name`, `webhook_trigger_secret`), attestation and signing
  (`kritis_note`, `kms_key_name`), Cloud Build service accounts
  (`cloud_build_sa_id`, `cloud_build_sa_email`, `cloud_build_robot_sa_email`),
  GKE cluster node service accounts (`sa-cluster-prod_email`,
  `sa-cluster-test_email`, `sa-cluster-dev_email`), Cloud Deploy target names
  (`cd_target_cluster-prod`, `cd_target_cluster-test`,
  `cd_target_cluster-dev`, `cd_target_run-prod`, `cd_target_run-test`,
  `cd_target_run-dev`), and VPC/subnet self-links (`vpc_self_link`,
  `vpc_hub_subnet_self_link`, `vpc_dev_subnet_self_link`,
  `vpc_test_subnet_self_link`, `vpc_prod_subnet_self_link`).
- Modules (`main.tf`, `network.tf`, `workstations.tf`, `build.tf`,
  `deploy.tf`, `runtime.tf`, `misc.tf`): Instantiates
  `cloud-foundation-fabric` `v34.0.0` modules `project` (`module.project`),
  `net-vpc` (`module.vpc`), `net-cloudnat` (`module.nat`), `net-vpc-firewall`
  (`module.fw`), `iam-service-account` (`module.sa-ws`, `module.sa-cb`,
  `module.sa-cd-prod`, `module.sa-cd-test`, `module.sa-cd-dev`,
  `module.sa-cluster-prod`, `module.sa-cluster-test`, `module.sa-cluster-dev`,
  `module.sa-demo-prod`, `module.sa-demo-test`, `module.sa-demo-dev`), and
  `gke-cluster-autopilot` (`module.cluster-prod`, `module.cluster-test`,
  `module.cluster-dev`).
- Direct resources and data sources (`main.tf`, `workstations.tf`,
  `source.tf`, `deploy.tf`, `security.tf`, `misc.tf`):
  `google_project_iam_member` developer role bindings,
  `google_workstations_workstation_cluster.cicd_foundation`,
  `google_workstations_workstation_config.cicd_foundation`,
  `google_secure_source_manager_instance.source`, `random_id.random`,
  `google_secret_manager_secret.webhook_trigger`,
  `google_secret_manager_secret_version.webhook_trigger`,
  `google_secret_manager_secret_iam_policy.policy`,
  `google_clouddeploy_target` (`cluster-prod`, `cluster-test`, `cluster-dev`,
  `run-prod`, `run-test`, `run-dev`),
  `google_binary_authorization_policy.policy`,
  `google_container_analysis_note.vulnz-attestor`,
  `google_container_analysis_note_iam_member.vulnz-attestor-services`,
  `google_binary_authorization_attestor.vulnz-attestor`,
  `google_kms_key_ring.keyring`, `google_kms_crypto_key.vulnz-attestor-key`,
  `google_kms_crypto_key_iam_member.vulnz-attestor`,
  `data.google_kms_crypto_key_version.vulnz-attestor`, and
  `google_service_account_iam_binding.sa-demo-{prod,test,dev}-iam`.

## Invariants

- Single-project simplified topology: `module.project` references a
  pre-existing Google Cloud project (`project_create = false`) with Shared VPC
  host disabled (`shared_vpc_host_config.enabled = false`), consolidating hub
  and runtime environments (`dev`, `test`, `prod`) into one project and one
  VPC.
- Subnet and secondary range structure: `module.vpc` must define regional
  subnets named `hub`, `dev`, `test`, and `prod` (plus proxy-only subnet
  `proxy`), where `dev`, `test`, and `prod` subnets each provide secondary IP
  ranges strictly keyed as `pods` and `services` for the GKE Autopilot
  clusters.
- Firewall factory file paths: `module.fw` expects YAML configuration files at
  `firewall/rules` (`rules_folder`) and `firewall/cidrs.yaml`
  (`cidr_tpl_file`) relative to the root [`simplified`](../EGM.md) module
  working directory.
- Binary Authorization policy enforcement tiers: All three GKE Autopilot
  clusters enable Binary Authorization (`binary_authorization = true`), while
  `google_binary_authorization_policy.policy` enforces attestation by
  `vulnz-attestor` (`REQUIRE_ATTESTATION` / `ENFORCED_BLOCK_AND_AUDIT_LOG`) by
  default (applying to `prod`) and explicitly overrides `cluster-test` and
  `cluster-dev` with `ALWAYS_ALLOW` / `DRYRUN_AUDIT_LOG_ONLY`.
- Cloud Deploy production approval gate: Production Cloud Deploy targets
  (`cluster-prod` and `run-prod`) enforce `require_approval = true`, whereas
  `dev` and `test` targets (`cluster-dev`, `cluster-test`, `run-dev`,
  `run-test`) set `require_approval = false`.
- Cryptographic signing alignment: The KMS key `vulnz-attestor-key` uses
  purpose `ASYMMETRIC_SIGN` with algorithm `RSA_SIGN_PKCS1_4096_SHA512` in a
  `global` keyring, and `module.sa-cb` (Cloud Build service account) is
  granted `roles/cloudkms.signer` on the key and
  `roles/containeranalysis.notes.attacher` on the project.

## Side Effects

- Enables project APIs (`artifactregistry`, `binaryauthorization`,
  `cloudbuild`, `clouddeploy`, `cloudkms`, `compute`, `container`,
  `containeranalysis`, `containerscanning`, `ondemandscanning`, `orgpolicy`,
  `run`, `servicenetworking`, `secretmanager`, `securesourcemanager`,
  `workstations`) and binds project-level IAM roles for developers and service
  accounts.
- Provisions a VPC (`vpc`) with 4 primary subnets (`hub`, `dev`, `test`,
  `prod`), 1 regional proxy-only subnet (`proxy`), Private Service Access
  (PSA) ranges, a Cloud NAT router/gateway, and VPC firewall rules.
- Provisions a Cloud Workstations cluster and workstation configuration (using
  `google-beta`, `e2-standard-4` default GCE host, 200GB `/home` persistent
  disk, private IP by default) and its dedicated service account.
- Provisions a Secure Source Manager instance (`source`) in `var.ssm_region`
  and a Secret Manager secret (`webhook-trigger`) populated with a random
  64-byte hex value accessible to the Cloud Build service agent.
- Provisions dedicated IAM service accounts for Cloud Build (`sa-cb`), Cloud
  Deploy (`sa-cd-prod`, `sa-cd-test`, `sa-cd-dev`), GKE clusters
  (`sa-cluster-prod`, `sa-cluster-test`, `sa-cluster-dev`), and demo
  applications (`sa-demo-prod`, `sa-demo-test`, `sa-demo-dev` in `misc.tf`,
  with `roles/iam.serviceAccountUser` granted to `sa-cd-{prod,test,dev}`).
- Provisions three GKE Autopilot clusters (`<cluster_name>-prod`,
  `<cluster_name>-test`, `<cluster_name>-dev`) and six Cloud Deploy targets
  (`cluster-prod`, `cluster-test`, `cluster-dev`, `run-prod`, `run-test`,
  `run-dev`).
- Provisions a global Cloud KMS keyring and asymmetric signing key, a
  Container Analysis attestation note, a Binary Authorization attestor, and
  the project-wide Binary Authorization admission policy.
