# Copyright 2023-2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  stage_runtime_projects = {
    for stage_key, stage_value in var.stages :
    stage_key => coalesce(stage_value.runtime_project_id, stage_value.project_id, var.project_id)
  }

  cluster_details = {
    for stage_key, stage_value in var.stages : stage_key => {
      full_name       = stage_value.gke_cluster
      runtime_project = local.stage_runtime_projects[stage_key]
      parsed          = regex("projects/(?:[^/]+)/locations/([^/]+)/clusters/([^/]+)", stage_value.gke_cluster)
    } if stage_value.gke_cluster != null
  }

  # Boolean indicating whether a Kritis signer image is provided.
  use_binary_authorization = var.kritis_signer_image != null && var.kritis_signer_image != ""

  # Boolean indicating whether to create binauth resources.
  create_binary_authorization_resources = local.use_binary_authorization || var.binary_authorization_always_create

  binauth_policy_projects = local.create_binary_authorization_resources ? toset(distinct(concat(
    [var.project_id],
    [
      for stage_key, stage_value in var.stages :
      local.stage_runtime_projects[stage_key]
      if stage_value.gke_cluster != null
    ]
  ))) : toset([])
}

resource "google_project_service_identity" "binauth" {
  for_each = local.binauth_policy_projects
  provider = google-beta

  project = each.key
  service = "binaryauthorization.googleapis.com"

  depends_on = [
    module.project_services
  ]
}

resource "google_container_analysis_note" "vulnz_attestor" {
  count = local.create_binary_authorization_resources ? 1 : 0

  project = data.google_project.project.project_id
  name    = "${local.prefix}${var.vulnz_attestor_name}"
  attestation_authority {
    hint {
      human_readable_name = "Vulnerability Attestor"
    }
  }
}

resource "google_container_analysis_note_iam_member" "vulnz_attestor_services" {
  for_each = local.binauth_policy_projects

  project = google_container_analysis_note.vulnz_attestor[0].project
  note    = google_container_analysis_note.vulnz_attestor[0].name
  role    = "roles/containeranalysis.notes.occurrences.viewer"
  member  = "serviceAccount:${google_project_service_identity.binauth[each.key].email}"
}

resource "google_kms_key_ring" "keyring" {
  count = local.create_binary_authorization_resources ? 1 : 0

  project  = local.kms_project_id
  name     = "${local.prefix}${var.kms_keyring_name}"
  location = var.kms_keyring_location
}

resource "google_kms_crypto_key" "vulnz_attestor_key" {
  count = local.create_binary_authorization_resources ? 1 : 0

  name     = "${local.prefix}${var.kms_key_name}"
  key_ring = google_kms_key_ring.keyring[0].id
  purpose  = "ASYMMETRIC_SIGN"
  version_template {
    algorithm = var.kms_signing_alg
  }
  labels                     = local.common_labels
  destroy_scheduled_duration = "${var.kms_key_destroy_scheduled_duration_days * 24 * 60 * 60}s"

  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "google_kms_crypto_key_iam_member" "vulnz_attestor" {
  count = local.create_binary_authorization_resources ? 1 : 0

  crypto_key_id = google_kms_crypto_key.vulnz_attestor_key[0].id
  role          = "roles/cloudkms.signerVerifier"
  member        = module.service_account_cloud_build.iam_email
}

data "google_kms_crypto_key_version" "vulnz_attestor" {
  count = local.create_binary_authorization_resources ? 1 : 0

  crypto_key = google_kms_crypto_key.vulnz_attestor_key[0].id
}

resource "google_binary_authorization_attestor" "vulnz_attestor" {
  count = local.create_binary_authorization_resources ? 1 : 0

  project = google_container_analysis_note.vulnz_attestor[0].project
  name    = "${local.prefix}${var.vulnz_attestor_name}"
  attestation_authority_note {
    note_reference = google_container_analysis_note.vulnz_attestor[0].name
    public_keys {
      id = data.google_kms_crypto_key_version.vulnz_attestor[0].id
      pkix_public_key {
        public_key_pem      = data.google_kms_crypto_key_version.vulnz_attestor[0].public_key[0].pem
        signature_algorithm = data.google_kms_crypto_key_version.vulnz_attestor[0].public_key[0].algorithm
      }
    }
  }
}

resource "google_binary_authorization_attestor_iam_member" "vulnz_attestor_verifiers" {
  for_each = local.binauth_policy_projects

  project  = google_binary_authorization_attestor.vulnz_attestor[0].project
  attestor = google_binary_authorization_attestor.vulnz_attestor[0].name
  role     = "roles/binaryauthorization.attestorsVerifier"
  member   = "serviceAccount:${google_project_service_identity.binauth[each.key].email}"
}

resource "google_binary_authorization_policy" "policy" {
  for_each = local.binauth_policy_projects

  project                       = each.key
  global_policy_evaluation_mode = "ENABLE"
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [
      google_binary_authorization_attestor.vulnz_attestor[0].id
    ]
  }
  dynamic "cluster_admission_rules" {
    for_each = {
      for stage_key, detail in local.cluster_details :
      stage_key => detail
      if detail.runtime_project == each.key
    }

    content {
      cluster          = "${cluster_admission_rules.value.parsed[0]}.${cluster_admission_rules.value.parsed[1]}"
      evaluation_mode  = var.stages[cluster_admission_rules.key].binary_authorization_evaluation_mode
      enforcement_mode = var.stages[cluster_admission_rules.key].binary_authorization_enforcement_mode
      require_attestations_by = (
        var.stages[cluster_admission_rules.key].binary_authorization_evaluation_mode == "REQUIRE_ATTESTATION"
        ? [google_binary_authorization_attestor.vulnz_attestor[0].id]
        : null
      )
    }
  }
}
