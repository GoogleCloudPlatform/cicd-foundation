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

# CI/CD Workstations Module (`cicd_workstations`)

## Overview

The `cicd_workstations` Terraform module (`v8-0-0`, derived from
`GoogleCloudPlatform/cicd-foundation`) provisions and manages Google Cloud
Workstations infrastructure within an existing Google Cloud project. It enables
required Google Cloud APIs, creates a dedicated Cloud Workstations service
account, and provisions workstation clusters, workstation configurations
(supporting custom container images, GCE host settings, accelerators, boost
configurations, and `/home` persistent disks), workstation instances, and
associated IAM policies and bindings for workstation creators and instance
users.

## Interface

- `project_id` (string, required): Existing Google Cloud project ID where
  Cloud Workstations resources are deployed.
- `enable_apis` (bool, default `true`): Controls whether required project APIs
  (`cloudresourcemanager.googleapis.com`, `compute.googleapis.com`,
  `workstations.googleapis.com`) are enabled.
- `labels` (map(string), default `{}`): User-provided labels merged with
  `default_labels` and normalized to lowercase.
- `cws_service_account_name` (string, default `"workstations"`) and
  `cws_scopes` (list(string), default
  `["https://www.googleapis.com/auth/cloud-platform"]`): Service account name
  and OAuth scopes for workstation GCE hosts.
- `cws_clusters` (map(object), default `{}`): Map keyed by cluster ID defining
  `network`, `region`, `subnetwork`, optional `vpc_project` (for Shared VPC or
  cross-project networks), optional `domain_config`, and optional
  `private_cluster_config`.
- `cws_configs` (map(object), default `{}`): Map keyed by workstation
  configuration ID defining `cws_cluster` reference, optional custom container
  `image`, machine/disk/pool/timeout overrides, `accelerators`,
  `boost_configs`, `shielded_instance_config`, `/home` persistent disk
  settings (`persistent_disk_size_gb`, `persistent_disk_source_snapshot`,
  `persistent_disk_type`, `persistent_disk_fs_type`,
  `persistent_disk_reclaim_policy`), `creators` (list of user emails), and
  `instances` (list of objects with `name`, optional `display_name`, and
  `users`).
- Workstation configuration default variables: `boot_disk_size_gb_default`
  (`100`), `disable_public_ip_addresses_default` (`false`),
  `enable_nested_virtualization_default` (`true`),
  `idle_timeout_seconds_default` (`3600`), `machine_type_default`
  (`"n1-standard-96"`), `pool_size_default` (`0`),
  `persistent_disk_reclaim_policy_default` (`"RETAIN"`),
  `persistent_disk_fs_type_default` (`"ext4"`), `persistent_disk_type_default`
  (`"pd-balanced"`).
- Output `cws_clusters`: Map of provisioned
  `google_workstations_workstation_cluster` attributes (`id`, `network`,
  `subnetwork`, `location`, `private_cluster_config`) keyed by cluster key.
- Output `cws_configs`: Map of provisioned
  `google_workstations_workstation_config` attributes (`id`,
  `workstation_cluster_id`, `location`) keyed by configuration key.
- Output `cws_instances`: Map of provisioned `google_workstations_workstation`
  attributes (`id`, `workstation_config_id`, `workstation_cluster_id`,
  `location`, `workstation_id`) keyed by `${config_key}-${instance.name}`.
- Output `cws_service_account_email`: Email address of the provisioned Cloud
  Workstations service account (`module.cws_service_account.email`).

## Invariants

- Terraform version must be `>= 1.9.6` and `hashicorp/google` and
  `hashicorp/google-beta` providers must be `>= 6.11.0` (`terraform.tf`).
- Variable validation on `cws_configs`: For every configuration entry,
  `persistent_disk_source_snapshot` and `persistent_disk_size_gb` are mutually
  exclusive (`v.persistent_disk_source_snapshot == null ||
v.persistent_disk_size_gb == null`). When `persistent_disk_source_snapshot`
  is set, `persistent_disk_fs_type` does not fall back to
  `var.persistent_disk_fs_type_default` (`workstations.tf`).
- Referential integrity between configurations and clusters: Every
  `cws_configs[k].cws_cluster` must match a key in `var.cws_clusters` so
  `local.config_to_cluster_map` resolves in
  `google_workstations_workstation_cluster.cluster`.
- Network and subnetwork names in `var.cws_clusters` must be short names
  rather than full resource paths, as `local.cws_clusters` formats them into
  `projects/<vpc_project_or_project_id>/global/networks/<network>` and
  `projects/<vpc_project_or_project_id>/regions/<region>/subnetworks/<subnetwork>`.
- IAM member formatting invariant: Entries in `cws_configs[*].creators` and
  `cws_configs[*].instances[*].users` must be raw email addresses without IAM
  type prefixes, because `workstations.tf` and `iam.tf` unconditionally
  prepend `"user:"` (`"user:${user}"`).
- Label normalization and lifecycle invariant: All keys and values in
  `var.labels` and `local.default_labels` are converted to lowercase via
  `lower()`, with `local.default_labels` taking precedence on key collision;
  `lifecycle { ignore_changes = [labels] }` is enforced on cluster,
  configuration, and workstation resources.
- API preservation on destroy: `module.project_services` enforces
  `disable_services_on_destroy = false`.

## Side Effects

- Enables Google Cloud APIs (`cloudresourcemanager.googleapis.com`,
  `compute.googleapis.com`, `workstations.googleapis.com`) on `var.project_id`
  via
  `terraform-google-modules/project-factory/google//modules/project_services`
  (`v18.2.0`) when `var.enable_apis` is true.
- Creates a dedicated service account in `var.project_id` via
  `GoogleCloudPlatform/cloud-foundation-fabric//modules/iam-service-account`
  (`v45.0.0`) attached to all workstation host GCE instances.
- Provisions `google_workstations_workstation_cluster` resources (via
  `google-beta` provider) in the specified region, VPC network, and
  subnetwork.
- Provisions `google_workstations_workstation_config` resources (via
  `google-beta` provider) with GCE host settings, optional custom container
  image, and a persistent directory mounted at `/home`.
- Provisions `google_workstations_workstation` instances (via `google-beta`
  provider) flattened across all configurations under keys
  `${config_key}-${instance.name}`.
- Applies authoritative IAM policies
  (`google_workstations_workstation_config_iam_policy`) on workstation
  configurations with `creators`, binding
  `roles/workstations.workstationCreator` (overwriting any out-of-band IAM
  bindings on those configurations).
- Applies authoritative IAM policies
  (`google_workstations_workstation_iam_policy`) on each workstation instance,
  binding `roles/workstations.user` to the instance's `users` (overwriting any
  out-of-band IAM bindings on those instances).
- Grants project-level IAM bindings
  (`google_project_iam_member.workstation_user_roles`) for roles
  `roles/aiplatform.user`, `roles/browser`, `roles/cloudaicompanion.user`, and
  `roles/workstations.operationViewer`, plus service account impersonation
  (`google_service_account_iam_member.cws_sa_user` with
  `roles/iam.serviceAccountUser` on the workstation service account), to all
  unique users listed in `cws_configs[*].creators`.
