---
name: deploy-workstations
description: Assists Hackathon Admins and Platform Engineers in customizing the Cloud Workstations blueprint. Generates a terraform.tfvars file based on interactive Q&A and runs terraform plan.
license: Apache-2.0
metadata:
  author: sce-taid <sce@taid.me>
  resources:
    - docs/hackathon_guide.md
    - docs/workstations/design.md
    - infra/blueprints/workstations/terraform.tfvars.example
---

# Skill: Deploy Workstations

## Mission
Guide Hackathon Admins and Platform Engineers through adapting the Google Cloud CI/CD Foundation and Secure Developer Workstations blueprint for a hackathon. Output a complete, valid `terraform.tfvars` file ready for deployment and confirm the configuration via `terraform plan`.

## Execution Steps

When invoked, execute the following steps sequentially:

1. **Introduction & Questioning Phase**
   - Identify yourself as the assistant for deploying the workstations blueprint.
   - Ask the user the following questions interactively (allow them to answer one by one or in a block):
     1. What is the target `project_id`?
     2. What `region` and `zone` will you deploy to? (Suggest `us-central1` as a default).
     3. What is the networking strategy (Option A: Shared VPC Enterprise Standard vs Option B: Dedicated Project)? 
     4. Based on the strategy, what is the VPC network name, subnet, and if Shared VPC, the host project ID?
     5. Which users or Google Groups should receive the implicit CWS creator role? (e.g. `group:hackathon-participants@example.com`).
     6. What is the image governance strategy? (Option A: Public Open-Source vs Option B: Self-Governed SSM).

2. **Generation Phase**
   - Once you have the answers, read the file `infra/blueprints/workstations/terraform.tfvars.example`.
   - Modify the template with the values provided by the user. Do not remove essential structural elements; uncomment blocks as needed (like the Shared VPC project or creators).
   - Write the customized output to `infra/blueprints/workstations/terraform.tfvars`.

3. **Validation Phase**
   - Navigate to the correct directory (`infra/blueprints/workstations/`) and execute `terraform init` and `terraform plan`.
   - Report the outcome of the plan operation to the user, highlighting the resources that will be provisioned.

4. **Guidance Phase**
   - Remind the user about potential organizational policies to watch out for, specifically referencing:
     - `constraints/compute.vmExternalIpAccess`
     - `constraints/iam.allowedPolicyMemberDomains`
     - `constraints/compute.restrictSharedVpcSubnetworks`
   - Prompt the user whether they would like you to proceed with `terraform apply`, or if they want to execute it themselves using the `docs/iac/admin_guide.md` guidelines.
