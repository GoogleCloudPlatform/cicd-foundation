# Terraform Module establishing a CI/CD foundation (`cicd_foundation`)

This module provides a comprehensive CI/CD foundation on Google Cloud by
integrating CI/CD pipelines with managed development environments. It uses the
`cicd_pipelines` and `cicd_workstations` submodules to provision and configure:

*   **CI/CD Pipelines**: Sets up secure pipelines using Cloud Build, Artifact
    Registry, and Cloud Deploy for building, scanning, and deploying
    applications to Cloud Run or GKE. It also supports building custom images
    for Cloud Workstations, including scheduled rebuilds for patching.
*   **Managed Development Environments**: Sets up Cloud Workstations, allowing
    developers to use secure, pre-configured environments based on standard or
    custom images.

This foundation allows teams to automate application delivery and provide
developers with consistent and secure development environments.

## Features

*   Combines CI/CD pipelines for applications and Cloud Workstation custom
    images.
*   Provides managed Cloud Workstation environments via the `cicd_workstations`
    module.
*   Supports both Secure Source Manager and GitHub for triggering builds.
*   Includes security features like vulnerability scanning and Binary
    Authorization.
*   Allows scheduling of Cloud Workstation image rebuilds for security patching.

## Usage

Below is an example that sets up:
1.  A CI/CD pipeline for a Cloud Run application `my-app-1`.
2.  A CI/CD pipeline for a custom Cloud Workstation image `ide-1`, with a
    daily rebuild.
3.  A Cloud Workstation cluster and configuration using the custom `ide-1`
    image.

```terraform
module "cicd_foundation" {
  source = "github.com/GoogleCloudPlatform/cicd-foundation//infra/modules/cicd_foundation?ref=v5.0.1"

  project_id = "your-gcp-project-id"

  # Application to be deployed to Cloud Run
  apps = {
    "my-app-1" = {
      runtime = "cloudrun"
      stages = {
        "dev" = {}
      }
    }
  }

  # Custom image for Cloud Workstations
  cws_custom_images = {
    "ide-1" = {
      workstation_config = {
        ci_schedule      = "0 1 * * *" # Rebuild daily
        scheduler_region = "us-central1"
      }
    }
  }

  # Cloud Workstation cluster definition
  cws_clusters = {
    "us-central1-cluster" = {
      region     = "us-central1"
      network    = "projects/your-gcp-project-id/global/networks/default"
      subnetwork = "projects/your-gcp-project-id/regions/us-central1/subnetworks/default"
    }
  }

  # Cloud Workstation configuration using the custom image
  cws_configs = {
    "ide-1-config" = {
      cws_cluster                    = "us-central1-cluster"
      custom_image_names             = ["ide-1"]
      persistent_disk_type           = "pd-standard"
      persistent_disk_reclaim_policy = "RETAIN"
      creators = [
        "group:your-dev-group@example.com",
      ]
    }
  }
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_apps"></a> [apps](#input\_apps) | Map of applications to be deployed. | <pre>map(object({<br/>    build = optional(object({<br/>      # The relative path to the directory containing skaffold.yaml within the repository.<br/>      skaffold_path = optional(string)<br/>      # The timeout for the build in seconds.<br/>      timeout_seconds = optional(number)<br/>      # The machine type to use for the build.<br/>      machine_type = optional(string)<br/>      env          = optional(map(string), {})<br/>      })<br/>    )<br/>    runtime = optional(string, "cloudrun"),<br/>    stages  = optional(map(map(string))),<br/>    git_repo = optional(object({<br/>      url    = string<br/>      branch = string<br/>    })),<br/>    github = optional(object({<br/>      owner          = string<br/>      repo           = string<br/>      branch_pattern = string<br/>    })),<br/>    ssm = optional(object({<br/>      instance_id = string<br/>      repo_name   = string<br/>      branch      = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_apps_directory"></a> [apps\_directory](#input\_apps\_directory) | The root directory for applications in the repository. This is used to construct the path to an application's source code if `skaffold_path` is not specified. | `string` | `"apps"` | no |
| <a name="input_artifact_registry_id"></a> [artifact\_registry\_id](#input\_artifact\_registry\_id) | The ID of an existing Docker Artifact Registry to use. If null, a new one will be created. | `string` | `null` | no |
| <a name="input_artifact_registry_name"></a> [artifact\_registry\_name](#input\_artifact\_registry\_name) | The name of the Artifact Registry repository to create if artifact\_registry\_id is null. | `string` | `"cicd-foundation"` | no |
| <a name="input_artifact_registry_readers"></a> [artifact\_registry\_readers](#input\_artifact\_registry\_readers) | List of service account emails in IAM email format to grant Artifact Registry reader role. | `list(string)` | `[]` | no |
| <a name="input_artifact_registry_region"></a> [artifact\_registry\_region](#input\_artifact\_registry\_region) | The region for Artifact Registry. | `string` | `"us-central1"` | no |
| <a name="input_binary_authorization_always_create"></a> [binary\_authorization\_always\_create](#input\_binary\_authorization\_always\_create) | If true, create Binary Authorization resources even if kritis\_signer\_image is not provided. | `bool` | `false` | no |
| <a name="input_boot_disk_size_gb_default"></a> [boot\_disk\_size\_gb\_default](#input\_boot\_disk\_size\_gb\_default) | The default boot disk size in GB for Cloud Workstation instances. | `number` | `100` | no |
| <a name="input_build_machine_type_default"></a> [build\_machine\_type\_default](#input\_build\_machine\_type\_default) | The default machine type to use for Cloud Build jobs. | `string` | `"UNSPECIFIED"` | no |
| <a name="input_build_timeout_default_seconds"></a> [build\_timeout\_default\_seconds](#input\_build\_timeout\_default\_seconds) | The default timeout in seconds for Cloud Build jobs. | `number` | `7200` | no |
| <a name="input_canary_route_update_wait_time_seconds"></a> [canary\_route\_update\_wait\_time\_seconds](#input\_canary\_route\_update\_wait\_time\_seconds) | The time (in seconds) to wait for network route updates during GKE canary deployments. | `number` | `60` | no |
| <a name="input_canary_verify"></a> [canary\_verify](#input\_canary\_verify) | Whether to enable verification steps for canary deployments in Cloud Deploy. | `bool` | `true` | no |
| <a name="input_cloud_build_api_key_display_name"></a> [cloud\_build\_api\_key\_display\_name](#input\_cloud\_build\_api\_key\_display\_name) | The display name of the API key for Cloud Build. | `string` | `"API key for Cloud Build"` | no |
| <a name="input_cloud_build_api_key_name"></a> [cloud\_build\_api\_key\_name](#input\_cloud\_build\_api\_key\_name) | The name of the API key for Cloud Build.<br/>You can import an existing API key by specifying its name here<br/>and running `terraform import`. | `string` | `"cloudbuild"` | no |
| <a name="input_cloud_build_peered_network"></a> [cloud\_build\_peered\_network](#input\_cloud\_build\_peered\_network) | If set, configures Cloud Build to use a private worker pool connected to the specified VPC network. The network must be provided in the format projects/{project}/global/networks/{network}. | `string` | `null` | no |
| <a name="input_cloud_build_pool_disk_size_gb"></a> [cloud\_build\_pool\_disk\_size\_gb](#input\_cloud\_build\_pool\_disk\_size\_gb) | The disk size in GB for Cloud Build worker pool workers. | `number` | `100` | no |
| <a name="input_cloud_build_pool_machine_type"></a> [cloud\_build\_pool\_machine\_type](#input\_cloud\_build\_pool\_machine\_type) | The machine type for Cloud Build worker pool workers. | `string` | `"e2-standard-2"` | no |
| <a name="input_cloud_build_pool_name"></a> [cloud\_build\_pool\_name](#input\_cloud\_build\_pool\_name) | The base name for the Cloud Build worker pools. Stage name will be appended. | `string` | `"worker-pool"` | no |
| <a name="input_cloud_build_region"></a> [cloud\_build\_region](#input\_cloud\_build\_region) | The region for Cloud Build. | `string` | `"us-central1"` | no |
| <a name="input_cloud_build_service_account_name"></a> [cloud\_build\_service\_account\_name](#input\_cloud\_build\_service\_account\_name) | The name of the Cloud Build service account to create. | `string` | `"cloudbuild"` | no |
| <a name="input_cws_clusters"></a> [cws\_clusters](#input\_cws\_clusters) | A map of Cloud Workstation clusters to create. The key of the map is used as the unique ID for the cluster. | <pre>map(object({<br/>    network     = string<br/>    region      = string<br/>    subnetwork  = string<br/>    vpc_project = optional(string)<br/>    domain_config = optional(object({<br/>      domain = string<br/>    }))<br/>    private_cluster_config = optional(object({<br/>      enable_private_endpoint = optional(bool, false)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_cws_configs"></a> [cws\_configs](#input\_cws\_configs) | A map of Cloud Workstation configurations. | <pre>map(object({<br/>    accelerators = optional(list(object({<br/>      type  = string<br/>      count = number<br/>    })), [])<br/>    boost_configs = optional(list(object({<br/>      id = string<br/>      accelerators = optional(list(object({<br/>        type  = string<br/>        count = number<br/>      })), [])<br/>      boot_disk_size_gb            = optional(number)<br/>      enable_nested_virtualization = optional(bool)<br/>      machine_type                 = optional(string)<br/>      pool_size                    = optional(number)<br/>    })), [])<br/>    boot_disk_size_gb = optional(number)<br/>    creators          = optional(list(string))<br/>    # In case custom images shall be used, the keys from the cws_custom_images map.<br/>    custom_image_names           = optional(list(string), [])<br/>    cws_cluster                  = string<br/>    disable_public_ip_addresses  = optional(bool)<br/>    display_name                 = optional(string)<br/>    enable_nested_virtualization = optional(bool)<br/>    idle_timeout_seconds         = optional(number)<br/>    image                        = optional(string)<br/>    instances = optional(list(object({<br/>      name         = string<br/>      display_name = optional(string)<br/>      users        = list(string)<br/>    })))<br/>    machine_type                    = optional(string)<br/>    persistent_disk_fs_type         = optional(string)<br/>    persistent_disk_reclaim_policy  = optional(string)<br/>    persistent_disk_size_gb         = optional(number)<br/>    persistent_disk_source_snapshot = optional(string)<br/>    persistent_disk_type            = optional(string)<br/>    pool_size                       = optional(number)<br/>    shielded_instance_config = optional(object({<br/>      enable_secure_boot          = optional(bool, true)<br/>      enable_vtpm                 = optional(bool, true)<br/>      enable_integrity_monitoring = optional(bool, true)<br/>    }), null)<br/>  }))</pre> | `{}` | no |
| <a name="input_cws_custom_images"></a> [cws\_custom\_images](#input\_cws\_custom\_images) | Map of applications as found within the apps/ folder of the repository,<br/>their build configuration, runtime, deployment stages and parameters. | <pre>map(object({<br/>    build = optional(object({<br/>      skaffold_path   = optional(string)<br/>      timeout_seconds = optional(number)<br/>      machine_type    = optional(string)<br/>      env             = optional(map(string), {})<br/>      })<br/>    )<br/>    workstation_config = optional(object({<br/>      scheduler_region = optional(string)<br/>      ci_schedule      = optional(string)<br/>      paused           = optional(bool, false)<br/>    })),<br/>    git_repo = optional(object({<br/>      url    = string<br/>      branch = string<br/>    })),<br/>    github = optional(object({<br/>      owner          = string<br/>      repo           = string<br/>      branch_pattern = string<br/>    })),<br/>    ssm = optional(object({<br/>      instance_id = string<br/>      repo_name   = string<br/>      branch      = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_cws_image_build_runner_role_create"></a> [cws\_image\_build\_runner\_role\_create](#input\_cws\_image\_build\_runner\_role\_create) | Whether to create the custom IAM role for the Cloud Workstation Image Build Runner. If false, the role is expected to exist. | `bool` | `true` | no |
| <a name="input_cws_image_build_runner_role_id"></a> [cws\_image\_build\_runner\_role\_id](#input\_cws\_image\_build\_runner\_role\_id) | The role\_id for the custom IAM role for the Cloud Workstation Image Build Runner. | `string` | `"cwsBuildRunner"` | no |
| <a name="input_cws_image_build_runner_role_title"></a> [cws\_image\_build\_runner\_role\_title](#input\_cws\_image\_build\_runner\_role\_title) | The title for the custom IAM role for the Cloud Workstation Image Build Runner. | `string` | `"Cloud Workstation Image Build Runner"` | no |
| <a name="input_cws_scopes"></a> [cws\_scopes](#input\_cws\_scopes) | The scope of the Cloud Workstations Service Account. | `list(string)` | <pre>[<br/>  "https://www.googleapis.com/auth/cloud-platform"<br/>]</pre> | no |
| <a name="input_cws_service_account_name"></a> [cws\_service\_account\_name](#input\_cws\_service\_account\_name) | Name of the Cloud Workstations Service Account. | `string` | `"workstations"` | no |
| <a name="input_default_ci_schedule"></a> [default\_ci\_schedule](#input\_default\_ci\_schedule) | The default cron schedule for continuous integration triggers in Cloud Scheduler if not specified in the application config. | `string` | `"0 0 * * *"` | no |
| <a name="input_deploy_region"></a> [deploy\_region](#input\_deploy\_region) | The region to use for Cloud Deploy resources. | `string` | `"us-central1"` | no |
| <a name="input_disable_public_ip_addresses_default"></a> [disable\_public\_ip\_addresses\_default](#input\_disable\_public\_ip\_addresses\_default) | The default for disabling public IP addresses for Cloud Workstation instances. | `bool` | `false` | no |
| <a name="input_docker_image_tag"></a> [docker\_image\_tag](#input\_docker\_image\_tag) | The tag of the gcr.io/cloud-builders/docker image to use. | `string` | `"20.10.24"` | no |
| <a name="input_enable_apis"></a> [enable\_apis](#input\_enable\_apis) | Whether to enable the required APIs for the module. | `bool` | `true` | no |
| <a name="input_enable_nested_virtualization_default"></a> [enable\_nested\_virtualization\_default](#input\_enable\_nested\_virtualization\_default) | The default for enabling nested virtualization for Cloud Workstation instances. | `bool` | `true` | no |
| <a name="input_gcloud_image_tag"></a> [gcloud\_image\_tag](#input\_gcloud\_image\_tag) | The tag of the gcr.io/google.com/cloudsdktool/cloud-sdk image to use. | `string` | `"562.0.0"` | no |
| <a name="input_git_branch_trigger"></a> [git\_branch\_trigger](#input\_git\_branch\_trigger) | The Secure Source Manager (SSM) branch that triggers Cloud Build on push. | `string` | `"main"` | no |
| <a name="input_git_branches_regexp_trigger"></a> [git\_branches\_regexp\_trigger](#input\_git\_branches\_regexp\_trigger) | A regular expression to match GitHub branches that trigger Cloud Build on push. | `string` | `"^main$"` | no |
| <a name="input_github_owner"></a> [github\_owner](#input\_github\_owner) | The owner of the GitHub repository (user or organization). | `string` | `null` | no |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | The name of the GitHub repository. | `string` | `null` | no |
| <a name="input_idle_timeout_seconds_default"></a> [idle\_timeout\_seconds\_default](#input\_idle\_timeout\_seconds\_default) | The default idle timeout in seconds for Cloud Workstation instances. | `number` | `3600` | no |
| <a name="input_kms_digest_alg"></a> [kms\_digest\_alg](#input\_kms\_digest\_alg) | The digest algorithm to use for KMS signing. | `string` | `"SHA512"` | no |
| <a name="input_kms_key_destroy_scheduled_duration_days"></a> [kms\_key\_destroy\_scheduled\_duration\_days](#input\_kms\_key\_destroy\_scheduled\_duration\_days) | The number of days to schedule the KMS key for destruction. | `number` | `60` | no |
| <a name="input_kms_key_name"></a> [kms\_key\_name](#input\_kms\_key\_name) | The name of the KMS key used for signing attestations. | `string` | `"vulnz-attestor-key"` | no |
| <a name="input_kms_keyring_location"></a> [kms\_keyring\_location](#input\_kms\_keyring\_location) | The location for the KMS keyring. | `string` | `"us-central1"` | no |
| <a name="input_kms_keyring_name"></a> [kms\_keyring\_name](#input\_kms\_keyring\_name) | The name of the KMS key ring. | `string` | `"vulnz-attestor-keyring"` | no |
| <a name="input_kms_signing_alg"></a> [kms\_signing\_alg](#input\_kms\_signing\_alg) | The KMS signing algorithm to use for the vulnerability attestor key. | `string` | `"RSA_SIGN_PKCS1_4096_SHA512"` | no |
| <a name="input_kritis_policy_default"></a> [kritis\_policy\_default](#input\_kritis\_policy\_default) | The default YAML content of the Kritis vulnerability signing policy. | `string` | `"apiVersion: kritis.grafeas.io/v1beta1\nkind: VulnzSigningPolicy\nmetadata:\n  name: cicd-foundation\nspec:\n  imageVulnerabilityRequirements:\n    maximumFixableSeverity: MEDIUM\n    maximumUnfixableSeverity: LOW\n    allowlistCVEs:\n#    - projects/goog-vulnz/notes/CVE-2023-39321\n"` | no |
| <a name="input_kritis_policy_file"></a> [kritis\_policy\_file](#input\_kritis\_policy\_file) | Path to a Kritis vulnerability signing policy YAML file. If null, the content from kritis\_policy\_default is used. | `string` | `null` | no |
| <a name="input_kritis_signer_image"></a> [kritis\_signer\_image](#input\_kritis\_signer\_image) | The container image reference for the Kritis signer. If empty, signing is disabled. | `string` | `""` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Common labels to be applied to resources. | `map(string)` | `{}` | no |
| <a name="input_machine_type_default"></a> [machine\_type\_default](#input\_machine\_type\_default) | The default machine type for Cloud Workstation instances. | `string` | `"n1-standard-96"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | A prefix to be added to resource names to ensure uniqueness. | `string` | `""` | no |
| <a name="input_persistent_disk_fs_type_default"></a> [persistent\_disk\_fs\_type\_default](#input\_persistent\_disk\_fs\_type\_default) | The default filesystem type for Cloud Workstation persistent disks. | `string` | `"ext4"` | no |
| <a name="input_persistent_disk_reclaim_policy_default"></a> [persistent\_disk\_reclaim\_policy\_default](#input\_persistent\_disk\_reclaim\_policy\_default) | The default reclaim policy for Cloud Workstation persistent disks. | `string` | `"RETAIN"` | no |
| <a name="input_persistent_disk_type_default"></a> [persistent\_disk\_type\_default](#input\_persistent\_disk\_type\_default) | The default disk type for Cloud Workstation persistent disks. | `string` | `"pd-balanced"` | no |
| <a name="input_pool_size_default"></a> [pool\_size\_default](#input\_pool\_size\_default) | The default pool size for Cloud Workstation instances. | `number` | `0` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project-ID that references existing project. | `string` | n/a | yes |
| <a name="input_runtimes"></a> [runtimes](#input\_runtimes) | List of supported runtime solutions for applications. | `list(string)` | <pre>[<br/>  "cloudrun",<br/>  "gke",<br/>  "workstations"<br/>]</pre> | no |
| <a name="input_scheduler_default_region"></a> [scheduler\_default\_region](#input\_scheduler\_default\_region) | The default region for the Cloud Scheduler if not specified in the application config. | `string` | `"us-central1"` | no |
| <a name="input_secret_manager_region"></a> [secret\_manager\_region](#input\_secret\_manager\_region) | The region for Secret Manager. | `string` | `"us-central1"` | no |
| <a name="input_secure_source_manager_always_create"></a> [secure\_source\_manager\_always\_create](#input\_secure\_source\_manager\_always\_create) | If true, create Secure Source Manager resources (instance, repository). These resources can be created even when a GitHub repository is also specified as the trigger source. | `bool` | `false` | no |
| <a name="input_secure_source_manager_ca_common_name"></a> [secure\_source\_manager\_ca\_common\_name](#input\_secure\_source\_manager\_ca\_common\_name) | The common name for the root CA certificate. | `string` | `"SSM Root CA"` | no |
| <a name="input_secure_source_manager_ca_key_algorithm"></a> [secure\_source\_manager\_ca\_key\_algorithm](#input\_secure\_source\_manager\_ca\_key\_algorithm) | The key algorithm to use for the root CA. | `string` | `"RSA_PKCS1_4096_SHA256"` | no |
| <a name="input_secure_source_manager_ca_lifetime_seconds"></a> [secure\_source\_manager\_ca\_lifetime\_seconds](#input\_secure\_source\_manager\_ca\_lifetime\_seconds) | The lifetime of the root CA certificate in seconds. | `string` | `"315360000s"` | no |
| <a name="input_secure_source_manager_ca_organization"></a> [secure\_source\_manager\_ca\_organization](#input\_secure\_source\_manager\_ca\_organization) | The organization name for the root CA certificate. | `string` | `"Terraform"` | no |
| <a name="input_secure_source_manager_ca_pool"></a> [secure\_source\_manager\_ca\_pool](#input\_secure\_source\_manager\_ca\_pool) | The CA pool to use for issuing instance certificates for a private Secure Source Manager instance, in the format projects/{project}/locations/{location}/caPools/{ca\_pool}. If null and secure\_source\_manager\_create\_ca\_pool is true, a new pool will be created. | `string` | `null` | no |
| <a name="input_secure_source_manager_create_ca_pool"></a> [secure\_source\_manager\_create\_ca\_pool](#input\_secure\_source\_manager\_create\_ca\_pool) | If true, and secure\_source\_manager\_ca\_pool is not set, creates a new CA Pool and Root CA for use with a private Secure Source Manager instance. | `bool` | `false` | no |
| <a name="input_secure_source_manager_deletion_policy"></a> [secure\_source\_manager\_deletion\_policy](#input\_secure\_source\_manager\_deletion\_policy) | The deletion policy for the Secure Source Manager instance and repository. One of DELETE, PREVENT, or ABANDON. | `string` | `"PREVENT"` | no |
| <a name="input_secure_source_manager_instance_id"></a> [secure\_source\_manager\_instance\_id](#input\_secure\_source\_manager\_instance\_id) | The full ID of an existing Secure Source Manager instance. If null, a new one will be created. | `string` | `null` | no |
| <a name="input_secure_source_manager_instance_name"></a> [secure\_source\_manager\_instance\_name](#input\_secure\_source\_manager\_instance\_name) | The name of the Secure Source Manager instance to create, if secure\_source\_manager\_instance\_id is null. | `string` | `"cicd-foundation"` | no |
| <a name="input_secure_source_manager_region"></a> [secure\_source\_manager\_region](#input\_secure\_source\_manager\_region) | The region for the Secure Source Manager instance, cf. https://cloud.google.com/secure-source-manager/docs/locations. | `string` | `"us-central1"` | no |
| <a name="input_secure_source_manager_repo_git_url_to_clone"></a> [secure\_source\_manager\_repo\_git\_url\_to\_clone](#input\_secure\_source\_manager\_repo\_git\_url\_to\_clone) | The URL of a Git repository to clone into the new Secure Source Manager repository. If null, cloning is skipped. | `string` | `null` | no |
| <a name="input_secure_source_manager_repo_name"></a> [secure\_source\_manager\_repo\_name](#input\_secure\_source\_manager\_repo\_name) | The name of the Secure Source Manager repository. | `string` | `"cicd-foundation"` | no |
| <a name="input_service_account_cloud_deploy_name"></a> [service\_account\_cloud\_deploy\_name](#input\_service\_account\_cloud\_deploy\_name) | The base name for the Cloud Deploy service accounts. Stage name will be appended. | `string` | `"cloud-deploy"` | no |
| <a name="input_skaffold_image_tag"></a> [skaffold\_image\_tag](#input\_skaffold\_image\_tag) | The tag of the gcr.io/k8s-skaffold/skaffold image to use. | `string` | `"v2.18.1"` | no |
| <a name="input_skaffold_output"></a> [skaffold\_output](#input\_skaffold\_output) | The filename for the Skaffold artifacts JSON output. | `string` | `"artifacts.json"` | no |
| <a name="input_skaffold_quiet"></a> [skaffold\_quiet](#input\_skaffold\_quiet) | Suppress Skaffold console output during builds. | `bool` | `false` | no |
| <a name="input_stages"></a> [stages](#input\_stages) | Map of deployment stages (e.g., dev, test, prod). Keys are stage names, values configure stage-specific settings like cluster, network, and Binary Authorization. | <pre>map(object({<br/>    cloud_run_region                      = optional(string)<br/>    gke_cluster                           = optional(string)<br/>    project_id                            = optional(string)<br/>    peered_network                        = optional(string)<br/>    require_approval                      = optional(bool, false)<br/>    canary_percentages                    = optional(list(number))<br/>    canary_verify                         = optional(bool, false)<br/>    binary_authorization_evaluation_mode  = optional(string, "ALWAYS_ALLOW")<br/>    binary_authorization_enforcement_mode = optional(string, "DRYRUN_AUDIT_LOG_ONLY")<br/>  }))</pre> | <pre>{<br/>  "dev": {},<br/>  "prod": {},<br/>  "test": {}<br/>}</pre> | no |
| <a name="input_vulnz_attestor_name"></a> [vulnz\_attestor\_name](#input\_vulnz\_attestor\_name) | The name of the Binary Authorization Attestor and the Container Analysis note. | `string` | `"vulnz-attestor"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloud_build_trigger_github_connection_needed"></a> [cloud\_build\_trigger\_github\_connection\_needed](#output\_cloud\_build\_trigger\_github\_connection\_needed) | Instructions to connect GitHub repository if using GitHub source. |
| <a name="output_cloud_build_trigger_ids"></a> [cloud\_build\_trigger\_ids](#output\_cloud\_build\_trigger\_ids) | The full resource IDs of the Cloud Build triggers. |
| <a name="output_cloud_build_trigger_trigger_ids"></a> [cloud\_build\_trigger\_trigger\_ids](#output\_cloud\_build\_trigger\_trigger\_ids) | The unique short IDs of the Cloud Build triggers. |
| <a name="output_cws_clusters"></a> [cws\_clusters](#output\_cws\_clusters) | A map of Cloud Workstation clusters, with their IDs and other attributes. |
| <a name="output_cws_service_account_email"></a> [cws\_service\_account\_email](#output\_cws\_service\_account\_email) | The email address of the Cloud Workstations Service Account. |
| <a name="output_secure_source_manager_instance_git_http"></a> [secure\_source\_manager\_instance\_git\_http](#output\_secure\_source\_manager\_instance\_git\_http) | The Git HTTP URI of the created Secure Source Manager instance. |
| <a name="output_secure_source_manager_instance_git_ssh"></a> [secure\_source\_manager\_instance\_git\_ssh](#output\_secure\_source\_manager\_instance\_git\_ssh) | The Git SSH URI of the created Secure Source Manager instance. |
| <a name="output_secure_source_manager_instance_html"></a> [secure\_source\_manager\_instance\_html](#output\_secure\_source\_manager\_instance\_html) | The HTML hostname of the created Secure Source Manager instance. |
| <a name="output_secure_source_manager_repository_git_html"></a> [secure\_source\_manager\_repository\_git\_html](#output\_secure\_source\_manager\_repository\_git\_html) | The Git HTML URI of the created Secure Source Manager repository. |
| <a name="output_secure_source_manager_repository_git_https"></a> [secure\_source\_manager\_repository\_git\_https](#output\_secure\_source\_manager\_repository\_git\_https) | The Git HTTP URI of the created Secure Source Manager repository. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
