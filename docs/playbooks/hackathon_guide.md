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

# Hackathon Organizer Guide: GNOME Desktop

This guide is designed for hackathon organizers, cloud architects, and technical mentors who want to deploy a high-performance, containerized GNOME desktop environment for event participants using the [Google Cloud Workstations](https://cloud.google.com/workstations) service and the [cicd-foundation](https://github.com/GoogleCloudPlatform/cicd-foundation) framework.

## 1. Roles & Responsibilities

Successfully running a hackathon on Google Cloud requires coordination between different core and optional personas:

### Core Roles

These roles are essential for any hackathon deployment.

| Role                      | Responsibilities                                                                                                                            |
| :------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------ |
| **Hackathon Admin**       | The technical lead responsible for the GCP projects. They manage the Terraform deployment, budget, and overall infrastructure availability. |
| **Hackathon Participant** | The end-users of the environment. They create and start their own workstations via the Cloud Console or CLI to work on their projects.      |

### Optional / Advisory Roles

These roles depend on the organizational context (e.g., enterprise vs. startup) and specific technical needs.

| Role                        | Responsibilities                                                                                                                                                                  |
| :-------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Googlers (PSO/CE/DA)**    | Professional Services (PSO), Customer Engineers (CE), or Developer Advocates (DA). They act as technical advisors to the organizers, helping navigate organizational constraints. |
| **Central Networking Team** | (In Customer Environments) Manages the Shared VPC host project. They must provide the service project with access to subnets and ensure appropriate firewall rules are in place.  |

## 2. Step-by-Step Deployment Guide

### Step 1: Foundation & Networking Strategy

The complexity of your deployment depends on the networking strategy:

- **Option A: Shared VPC (Enterprise Standard)**: If you are deploying into an existing corporate environment, you will likely use a **Shared VPC**. This requires coordination with your **Central Networking/IT Team** to ensure the Service Project has the correct subnet permissions and firewall rules.
- **Option B: Dedicated Project (Isolated Environment)**: If you are using a dedicated project for the hackathon with its own VPC, you are **good to go**. You have full control over the network and can proceed with the Terraform deployment independently.

### Step 2: Image Governance & Source Control

The `cicd-foundation` allows you to build your workstation image from different sources. Choose the one that matches your governance needs:

1.  **Public Open-Source (`git_repo`)**: Best for using the latest community updates directly from a public repository.
2.  **Self-Governed / Private (`ssm_repo`)**: Best for enterprise environments. Host the source code in your own **Secure Source Manager (SSM)** instance. This provides **maximum control and auditability**, allowing your security team to review all build hooks and configurations within your own project boundary.

### Step 3: Complete `terraform.tfvars` Example

Use this complete example to deploy the entire hackathon infrastructure via the `cicd-foundation`.

```hcl
project_id = "YOUR_HACKATHON_PROJECT"

# GNOME Image Build
cws_custom_images = {
  "gnome" : {
    # Using public open-sourced code
    git_repo = {
      url    = "https://github.com/GoogleCloudPlatform/cicd-foundation.git"
      branch = "main"
    }
    build = {
      skaffold_path = "apps/workstations/gnome/"
      machine_type  = "E2_HIGHCPU_32"
      # Pass environment variables to Skaffold to configure the Preflight UI source and Base Image
      env = {
        CWS_BASE_IMAGE_TAG = "latest"
        GCP_REGION         = "us-central1"
        PREFLIGHT_WEB_REPO = "https://github.com/GoogleCloudPlatform/cicd-foundation.git"
        PREFLIGHT_WEB_DIR  = "apps/workstations/preflight-web"
      }
    }
  }
}

# Workstation Cluster
cws_clusters = {
  "workstations" = {
    network    = "workstations"
    region     = "us-central1"
    subnetwork = "primary"
    # If using Shared VPC
    # network_project_id = "YOUR_SHARED_VPC_PROJECT_ID"
  }
}

# Workstation Configuration (The Blueprint for Participants)
cws_configs = {
  "custom" = {
    cws_cluster = "workstations"

    # ACCESS CONTROL: Decoupled Group Management
    # Pro Tip: Instead of adding 100 users, just add one Google Group.
    # Participants added to this group instantly get "Create" rights.
    creators = [
      "group:hackathon-participants@example.com",
      "user:lead-mentor@example.org"
    ]

    # Reference the custom GNOME image defined above
    custom_image_names = ["gnome"]

    # USER EXPERIENCE: Keep some instances ready for instant join
    pool_size = 5

    # HARDWARE SPECS
    machine_type                 = "e2-standard-8"
    enable_nested_virtualization = false
    persistent_disk_size_gb      = 200
    persistent_disk_type         = "pd-balanced"
  }
}
```

### Step 4: Execute the Deployment

For detailed instructions on running the Terraform commands, monitoring the build, and connecting via SSH, refer to the deployment guide:

👉 **[Infrastructure & Deployment Guide](../deployment_guide.md)**

## 3. Governance & Constraints

### Organizational Policies to Watch Out For

Organizers often encounter these common blocks in customer environments:

- **`constraints/compute.vmExternalIpAccess`**: Usually denies all. Ensure your Workstation Cluster is configured for **Private Gateway** access if participants connect over a VPN/Interconnect, or request an exception for the specific Service Project if using a Public Gateway.
- **`constraints/iam.allowedPolicyMemberDomains`**: Restricts which emails can be added to IAM. If participants are using personal emails (gmail.com), this policy must be relaxed or an exception granted.
- **`constraints/compute.restrictSharedVpcSubnetworks`**: Ensure the specific subnet you intend to use is allowed for the Service Project.

### VPC Service Controls (VPC-SC)

If the customer uses VPC-SC, you must include the Service Project and the Host Project in the same **Service Perimeter**. The `cicd-foundation` blueprint fully supports VPC-SC configurations by enabling private Google access and ensuring the internal control plane communication is within the perimeter.

## 4. Recommended Hackathon Timeline

A successful hackathon requires balancing technical validation with strategic alignment. Use this 4-week timeline as a blueprint:

| Phase                     | Timeline  | Milestone                  | Key Activities                                                                                                               |
| :------------------------ | :-------- | :------------------------- | :--------------------------------------------------------------------------------------------------------------------------- |
| **Phase 1: Scoping**      | **W-4**   | **Project Kickoff**        | Define use cases, select the GCP project, and identify the **Hackathon Admin**.                                              |
| **Phase 2: Foundation**   | **W-3**   | **Network Ready**          | Negotiate Shared VPC/Firewall rules with the customer's Central IT team.                                                     |
| **Phase 3: Provisioning** | **W-2**   | **Infrastructure Live**    | Execute `terraform apply` to build the image, cluster, and base configurations.                                              |
| **Phase 4: Validation**   | **W-1**   | **Technical Sign-off**     | **A week before the hackathon:** Create a test workstation and run `skills/validate-image-updates/scripts/run_all_tests.sh`. |
| **Phase 5: Execution**    | **Day 0** | **Participant Onboarding** | Participants join the Google Group and click "Create Workstation" for instant access.                                        |

## 5. Participant Onboarding

Once the `Hackathon Admin` has finished the deployment, participants can join:

1.  Go to the **Cloud Workstations** page in the GCP Console.
2.  Click **Create Workstation**.
3.  Select the **GNOME** configuration.
4.  Wait for the workstation to start, click **Launch**, and the immersive GNOME desktop will appear in the browser.

---

### Tips for Success

#### For Organizers

A week before the hackathon, create your own workstation instance and run the validation suite to ensure everything (networking, auth, extensions) is working:

1.  Connect to your workstation via SSH.
2.  Populate a `.env` file in the project root with the workstation details.
3.  Run `skills/validate-image-updates/scripts/run_all_tests.sh` to verify the environment.

#### For Googlers (PSO/CE/DA)

**Focus on the Business Objective.** On the day of the hackathon, your primary role is to act as a strategic mentor. Prioritize unblocking participants from technical hurdles so they can focus entirely on delivering their project's business value.

**Test before you deliver.** We encourage you to deploy this entire stack into your own internal sandbox (e.g., **Argolis**) first. This allows you to identify any organizational constraints or networking nuances in a safe environment before rolling it out to the customer.
