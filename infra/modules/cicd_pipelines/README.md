# Terraform Module for CI/CD pipelines (`cicd_pipelines`)

This module provisions a secure CI/CD environment on Google Cloud Platform using
Google Cloud-native services.

It sets up the necessary infrastructure for:

*   **Source Code Management**: Choose between
    [Secure Source Manager](https://cloud.google.com/secure-source-manager/docs/overview)
    or [GitHub](https://github.com) for source code hosting and CI triggers.
*   **Continuous Integration**:
    [Cloud Build](https://cloud.google.com/build/docs/overview) pipelines for
    building and testing applications.
*   **Artifact Management**:
    [Artifact Registry](https://cloud.google.com/artifact-registry/docs/overview)
    for storing and managing Docker container images.
*   **Continuous Deployment**:
    [Cloud Deploy](https://cloud.google.com/deploy/docs/overview) pipelines for
    deploying applications to various runtimes like Cloud Run, GKE, or Cloud
    Workstations.
*   **Security**:
    *   [Binary Authorization](https://cloud.google.com/binary-authorization/docs/overview)
        to ensure only trusted container images are deployed.
    *   Vulnerability scanning and attestation using
        [Kritis Signer](https://github.com/grafeas/kritis).
    *   [Key Management Service](https://cloud.google.com/kms/docs/key-management-service) for
        managing signing keys.
    *   [Secret Manager](https://cloud.google.com/secret-manager/docs/overview)
        for managing secrets like webhook keys.
*   **Automation**:
    [Cloud Scheduler](https://cloud.google.com/scheduler/docs/overview) for
    triggering periodic builds (e.g., for Cloud Workstations image patching).

## Features

*   **Flexible Source Control**: Supports both Secure Source Manager and GitHub
    for triggering builds on code push.
*   **Multiple Runtimes**: Supports deployments to Cloud Run, GKE, or Cloud
    Workstations via Cloud Deploy.
*   **Multi-Stage Deployments**: Define multiple deployment stages (e.g., dev,
    test, prod) with optional manual approvals between stages.
*   **Canary Deployments**: Supports canary deployment strategies for GKE targets.
*   **Vulnerability Scanning**: Integrates Kritis Signer for vulnerability
    scanning and creating Binary Authorization attestations during the build
    process.
*   **Customizable Builds**: Configure build machine types, timeouts, and
    dedicated worker pools via input variables.
*   **Cloud Workstations**: Includes support for scheduled rebuilding of Cloud
    Workstations base images to incorporate security patches.

## Usage

Below is a basic usage example deploying a Cloud Run application named
`my-app-1` to `dev` and `prod` stages.

```terraform
module "cicd_pipelines" {
  source = "github.com/GoogleCloudPlatform/cicd-foundation//infra/modules/cicd_pipelines?ref=v5.0.1"

  project_id = "your-gcp-project-id"
  namespace  = "my-app"

  # Use Secure Source Manager in us-central1
  secure_source_manager_region = "us-central1"

  # General stage configuration
  stages = {
    "dev" = {
      cloud_run_region = "us-central1"
    }
    "prod" = {
      cloud_run_region = "us-central1"
      require_approval = true # Require manual approval before deploying to prod
    }
  }

  # Application-specific configuration
  apps = {
    "my-app-1" = {
      runtime = "cloudrun"
      stages = {
        "dev"  = {}
        "prod" = {}
      }
    }
  }
}
```

**Note**: This module creates several resources and configures IAM permissions.
Ensure the identity running Terraform has sufficient permissions on the target project.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_apps"></a> [apps](#input\_apps) | Map of applications to be deployed. Keys are application names, values configure<br/>  build, runtime, and stage-specific parameters. The `stages` attribute is a map<br/>  where keys are stage names (e.g., 'dev', 'prod'). The value for each stage is<br/>  another map, where keys are used Cloud Deploy tags in the respective pipelines. | <pre>map(object({<br/>    build = optional(object({<br/>      # The relative path to the directory containing skaffold.yaml within the<br/>      # repository.<br/>      skaffold_path = optional(string)<br/>      # The timeout for the build in seconds.<br/>      timeout_seconds = optional(number)<br/>      # The machine type to use for the build.<br/>      machine_type = optional(string)<br/>      env          = optional(map(string), {})<br/>      })<br/>    )<br/>    runtime = optional(string, "cloudrun"),<br/>    stages  = optional(map(map(string))),<br/>    git_repo = optional(object({<br/>      url    = string<br/>      branch = string<br/>    })),<br/>    github = optional(object({<br/>      owner          = string<br/>      repo           = string<br/>      branch_pattern = string<br/>    })),<br/>    ssm = optional(object({<br/>      instance_id = string<br/>      repo_name   = string<br/>      branch      = string<br/>    })),<br/>    workstation_config = optional(object({<br/>      # The region to use for the Cloud Scheduler job.<br/>      scheduler_region = optional(string)<br/>      # The schedule for the Cloud Scheduler job in cron format (e.g., "0 1 * * *")<br/>      ci_schedule = optional(string)<br/>      paused      = optional(bool, false)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_apps_directory"></a> [apps\_directory](#input\_apps\_directory) | The root directory for applications in the repository. This is used to construct the path to an application's source code if `skaffold_path` is not specified. | `string` | `"apps"` | no |
| <a name="input_artifact_registry_id"></a> [artifact\_registry\_id](#input\_artifact\_registry\_id) | The ID of an existing Docker Artifact Registry to use. If null, a new one will be created. | `string` | `null` | no |
| <a name="input_artifact_registry_name"></a> [artifact\_registry\_name](#input\_artifact\_registry\_name) | The name of the Artifact Registry repository to create if artifact\_registry\_id is null. | `string` | `"cicd-foundation"` | no |
| <a name="input_artifact_registry_readers"></a> [artifact\_registry\_readers](#input\_artifact\_registry\_readers) | List of service account emails in IAM email format to grant Artifact Registry reader role. | `list(string)` | `[]` | no |
| <a name="input_artifact_registry_region"></a> [artifact\_registry\_region](#input\_artifact\_registry\_region) | The region to use for Artifact Registry resources. | `string` | `"us-central1"` | no |
| <a name="input_binary_authorization_always_create"></a> [binary\_authorization\_always\_create](#input\_binary\_authorization\_always\_create) | If true, create Binary Authorization resources even if kritis\_signer\_image is not provided. | `bool` | `false` | no |
| <a name="input_build_machine_type_default"></a> [build\_machine\_type\_default](#input\_build\_machine\_type\_default) | The default machine type to use for Cloud Build jobs. | `string` | `"UNSPECIFIED"` | no |
| <a name="input_build_timeout_default_seconds"></a> [build\_timeout\_default\_seconds](#input\_build\_timeout\_default\_seconds) | The default timeout in seconds for Cloud Build jobs. | `number` | `7200` | no |
| <a name="input_canary_route_update_wait_time_seconds"></a> [canary\_route\_update\_wait\_time\_seconds](#input\_canary\_route\_update\_wait\_time\_seconds) | The time (in seconds) to wait for network route updates during GKE canary deployments. | `number` | `60` | no |
| <a name="input_canary_verify"></a> [canary\_verify](#input\_canary\_verify) | Whether to enable verification steps for canary deployments in Cloud Deploy. | `bool` | `true` | no |
| <a name="input_cloud_build_api_key_display_name"></a> [cloud\_build\_api\_key\_display\_name](#input\_cloud\_build\_api\_key\_display\_name) | The display name of the API key for Cloud Build. | `string` | `"API key for Cloud Build"` | no |
| <a name="input_cloud_build_api_key_name"></a> [cloud\_build\_api\_key\_name](#input\_cloud\_build\_api\_key\_name) | The name of the API key for Cloud Build.<br/>You can import an existing API key by specifying its name here<br/>and running `terraform import`. | `string` | `"cloudbuild"` | no |
| <a name="input_cloud_build_peered_network"></a> [cloud\_build\_peered\_network](#input\_cloud\_build\_peered\_network) | If set, configures Cloud Build to use a private worker pool connected to the specified VPC network. | `string` | `null` | no |
| <a name="input_cloud_build_pool_disk_size_gb"></a> [cloud\_build\_pool\_disk\_size\_gb](#input\_cloud\_build\_pool\_disk\_size\_gb) | The disk size in GB for Cloud Build worker pool workers. | `number` | `100` | no |
| <a name="input_cloud_build_pool_machine_type"></a> [cloud\_build\_pool\_machine\_type](#input\_cloud\_build\_pool\_machine\_type) | The machine type for Cloud Build worker pool workers. | `string` | `"e2-standard-2"` | no |
| <a name="input_cloud_build_pool_name"></a> [cloud\_build\_pool\_name](#input\_cloud\_build\_pool\_name) | The base name for the Cloud Build worker pools. Stage name will be appended. | `string` | `"worker-pool"` | no |
| <a name="input_cloud_build_region"></a> [cloud\_build\_region](#input\_cloud\_build\_region) | The region to use for Cloud Build resources. | `string` | `"us-central1"` | no |
| <a name="input_cloud_build_service_account_name"></a> [cloud\_build\_service\_account\_name](#input\_cloud\_build\_service\_account\_name) | The name of the Cloud Build service account to create. | `string` | `"cloudbuild"` | no |
| <a name="input_cws_image_build_runner_role_create"></a> [cws\_image\_build\_runner\_role\_create](#input\_cws\_image\_build\_runner\_role\_create) | Whether to create the custom IAM role for the Cloud Workstation Image Build Runner. If false, the role is expected to exist. | `bool` | `true` | no |
| <a name="input_cws_image_build_runner_role_id"></a> [cws\_image\_build\_runner\_role\_id](#input\_cws\_image\_build\_runner\_role\_id) | The role\_id for the custom IAM role for the Cloud Workstation Image Build Runner. | `string` | `"cwsBuildRunner"` | no |
| <a name="input_cws_image_build_runner_role_title"></a> [cws\_image\_build\_runner\_role\_title](#input\_cws\_image\_build\_runner\_role\_title) | The title for the custom IAM role for the Cloud Workstation Image Build Runner. | `string` | `"Cloud Workstation Image Build Runner"` | no |
| <a name="input_default_ci_schedule"></a> [default\_ci\_schedule](#input\_default\_ci\_schedule) | The default cron schedule for continuous integration triggers in Cloud Scheduler if not specified in the application config. | `string` | `"0 0 * * *"` | no |
| <a name="input_deploy_region"></a> [deploy\_region](#input\_deploy\_region) | The region to use for Cloud Deploy resources. | `string` | `"us-central1"` | no |
| <a name="input_docker_image_tag"></a> [docker\_image\_tag](#input\_docker\_image\_tag) | The tag of the gcr.io/cloud-builders/docker image to use. | `string` | `"20.10.24"` | no |
| <a name="input_enable_apis"></a> [enable\_apis](#input\_enable\_apis) | Whether to enable the required APIs for the module. | `bool` | `true` | no |
| <a name="input_gcloud_image_tag"></a> [gcloud\_image\_tag](#input\_gcloud\_image\_tag) | The tag of the gcr.io/google.com/cloudsdktool/cloud-sdk image to use. | `string` | `"562.0.0"` | no |
| <a name="input_git_branch_trigger"></a> [git\_branch\_trigger](#input\_git\_branch\_trigger) | The Secure Source Manager (SSM) branch that triggers Cloud Build on push. | `string` | `"main"` | no |
| <a name="input_git_branches_regexp_trigger"></a> [git\_branches\_regexp\_trigger](#input\_git\_branches\_regexp\_trigger) | A regular expression to match GitHub branches that trigger Cloud Build on push. | `string` | `"^main$"` | no |
| <a name="input_github_owner"></a> [github\_owner](#input\_github\_owner) | The owner of the GitHub repository (user or organization). | `string` | `null` | no |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | The name of the GitHub repository. | `string` | `null` | no |
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
| <a name="input_namespace"></a> [namespace](#input\_namespace) | A prefix to be added to resource names to ensure uniqueness. | `string` | `""` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the Google Cloud project where resources will be deployed. | `string` | n/a | yes |
| <a name="input_runtimes"></a> [runtimes](#input\_runtimes) | List of supported runtime solutions for applications. | `list(string)` | <pre>[<br/>  "cloudrun",<br/>  "gke",<br/>  "workstations"<br/>]</pre> | no |
| <a name="input_scheduler_default_region"></a> [scheduler\_default\_region](#input\_scheduler\_default\_region) | The default region for the Cloud Scheduler if not specified in the application config. | `string` | `"us-central1"` | no |
| <a name="input_secret_manager_region"></a> [secret\_manager\_region](#input\_secret\_manager\_region) | The region for the Secret Manager, cf. https://cloud.google.com/secret-manager/docs/locations. | `string` | `"us-central1"` | no |
| <a name="input_secure_source_manager_always_create"></a> [secure\_source\_manager\_always\_create](#input\_secure\_source\_manager\_always\_create) | If true, create Secure Source Manager resources (instance, repository). These resources can be created even when a GitHub repository is also specified as the trigger source. | `bool` | `false` | no |
| <a name="input_secure_source_manager_ca_common_name"></a> [secure\_source\_manager\_ca\_common\_name](#input\_secure\_source\_manager\_ca\_common\_name) | The common name for the root CA certificate. | `string` | `"SSM Root CA"` | no |
| <a name="input_secure_source_manager_ca_key_algorithm"></a> [secure\_source\_manager\_ca\_key\_algorithm](#input\_secure\_source\_manager\_ca\_key\_algorithm) | The key algorithm to use for the root CA. | `string` | `"RSA_PKCS1_4096_SHA256"` | no |
| <a name="input_secure_source_manager_ca_lifetime_seconds"></a> [secure\_source\_manager\_ca\_lifetime\_seconds](#input\_secure\_source\_manager\_ca\_lifetime\_seconds) | The lifetime of the root CA certificate in seconds. | `string` | `"315360000s"` | no |
| <a name="input_secure_source_manager_ca_organization"></a> [secure\_source\_manager\_ca\_organization](#input\_secure\_source\_manager\_ca\_organization) | The organization name for the root CA certificate. | `string` | `"example.com"` | no |
| <a name="input_secure_source_manager_ca_pool"></a> [secure\_source\_manager\_ca\_pool](#input\_secure\_source\_manager\_ca\_pool) | The CA pool to use for issuing instance certificates for a private Secure Source Manager instance. If null and secure\_source\_manager\_create\_ca\_pool is true, a new pool will be created. | `string` | `null` | no |
| <a name="input_secure_source_manager_create_ca_pool"></a> [secure\_source\_manager\_create\_ca\_pool](#input\_secure\_source\_manager\_create\_ca\_pool) | If true, and secure\_source\_manager\_ca\_pool is not set, creates a new CA Pool and Root CA for use with a private Secure Source Manager instance. | `bool` | `false` | no |
| <a name="input_secure_source_manager_deletion_policy"></a> [secure\_source\_manager\_deletion\_policy](#input\_secure\_source\_manager\_deletion\_policy) | The deletion policy for the Secure Source Manager instance and repository. One of DELETE, PREVENT, or ABANDON. | `string` | `"PREVENT"` | no |
| <a name="input_secure_source_manager_instance_id"></a> [secure\_source\_manager\_instance\_id](#input\_secure\_source\_manager\_instance\_id) | The full ID of an existing Secure Source Manager instance. If null, a new one will be created. | `string` | `null` | no |
| <a name="input_secure_source_manager_instance_name"></a> [secure\_source\_manager\_instance\_name](#input\_secure\_source\_manager\_instance\_name) | The name of the Secure Source Manager instance. | `string` | `"cicd-foundation"` | no |
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
| <a name="output_artifact_registry_repository"></a> [artifact\_registry\_repository](#output\_artifact\_registry\_repository) | The Artifact Registry repository object. |
| <a name="output_artifact_registry_repository_uri"></a> [artifact\_registry\_repository\_uri](#output\_artifact\_registry\_repository\_uri) | The URI of the Artifact Registry repository. |
| <a name="output_binary_authorization_policy_id"></a> [binary\_authorization\_policy\_id](#output\_binary\_authorization\_policy\_id) | The ID of the created Binary Authorization Policy. |
| <a name="output_cloud_build_api_key"></a> [cloud\_build\_api\_key](#output\_cloud\_build\_api\_key) | The API key for Cloud Build webhook triggers. |
| <a name="output_cloud_build_service_account_email"></a> [cloud\_build\_service\_account\_email](#output\_cloud\_build\_service\_account\_email) | The email of the Cloud Build service account. |
| <a name="output_cloud_build_service_account_id"></a> [cloud\_build\_service\_account\_id](#output\_cloud\_build\_service\_account\_id) | The ID of the Cloud Build service account. |
| <a name="output_cloud_build_trigger_github_connection_needed"></a> [cloud\_build\_trigger\_github\_connection\_needed](#output\_cloud\_build\_trigger\_github\_connection\_needed) | Instructions to connect GitHub repository if using GitHub source. |
| <a name="output_cloud_build_trigger_id"></a> [cloud\_build\_trigger\_id](#output\_cloud\_build\_trigger\_id) | The full resource ID of the Cloud Build trigger. |
| <a name="output_cloud_build_trigger_trigger_id"></a> [cloud\_build\_trigger\_trigger\_id](#output\_cloud\_build\_trigger\_trigger\_id) | The unique short ID of the Cloud Build trigger. |
| <a name="output_cloud_build_worker_pool_ids"></a> [cloud\_build\_worker\_pool\_ids](#output\_cloud\_build\_worker\_pool\_ids) | A map of Cloud Build Worker Pool IDs, keyed by stage name. |
| <a name="output_cws_image_build_runner_service_account_email"></a> [cws\_image\_build\_runner\_service\_account\_email](#output\_cws\_image\_build\_runner\_service\_account\_email) | The email of the Cloud Workstation Image Build Runner service account. |
| <a name="output_cws_image_build_runner_service_account_id"></a> [cws\_image\_build\_runner\_service\_account\_id](#output\_cws\_image\_build\_runner\_service\_account\_id) | The ID of the Cloud Workstation Image Build Runner service account. |
| <a name="output_secure_source_manager_instance_git_http"></a> [secure\_source\_manager\_instance\_git\_http](#output\_secure\_source\_manager\_instance\_git\_http) | The Git HTTP URI of the created Secure Source Manager instance. |
| <a name="output_secure_source_manager_instance_git_ssh"></a> [secure\_source\_manager\_instance\_git\_ssh](#output\_secure\_source\_manager\_instance\_git\_ssh) | The Git SSH URI of the created Secure Source Manager instance. |
| <a name="output_secure_source_manager_instance_html"></a> [secure\_source\_manager\_instance\_html](#output\_secure\_source\_manager\_instance\_html) | The HTML hostname of the Secure Source Manager instance. |
| <a name="output_secure_source_manager_instance_id"></a> [secure\_source\_manager\_instance\_id](#output\_secure\_source\_manager\_instance\_id) | The ID of the Secure Source Manager instance. |
| <a name="output_secure_source_manager_repository_git_html"></a> [secure\_source\_manager\_repository\_git\_html](#output\_secure\_source\_manager\_repository\_git\_html) | The Git HTML URI of the created Secure Source Manager repository. |
| <a name="output_secure_source_manager_repository_git_https"></a> [secure\_source\_manager\_repository\_git\_https](#output\_secure\_source\_manager\_repository\_git\_https) | The Git HTTP URI of the created Secure Source Manager repository. |
| <a name="output_secure_source_manager_repository_id"></a> [secure\_source\_manager\_repository\_id](#output\_secure\_source\_manager\_repository\_id) | The full ID of the created Secure Source Manager repository resource. |
| <a name="output_secure_source_manager_repository_name"></a> [secure\_source\_manager\_repository\_name](#output\_secure\_source\_manager\_repository\_name) | The short name (repository\_id) of the created Secure Source Manager repository. |
| <a name="output_webhook_trigger_secret_id"></a> [webhook\_trigger\_secret\_id](#output\_webhook\_trigger\_secret\_id) | The ID of the webhook trigger secret. |
| <a name="output_webhook_trigger_secret_name"></a> [webhook\_trigger\_secret\_name](#output\_webhook\_trigger\_secret\_name) | The name of the webhook trigger secret. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
