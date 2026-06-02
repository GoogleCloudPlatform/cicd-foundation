---
name: validate-image-updates
description: Enforces the mandatory sequential validation workflow when a new workstation image is built or the codebase is modified.
license: Apache-2.0
allowed-tools: skills/validate-image-updates/scripts/run_all_tests.sh skills/validate-image-updates/scripts/run_integration_tests.sh skills/validate-image-updates/scripts/run_local_tests.sh
metadata:
  author: sce-taid <sce@taid.me>
  resources:
    - AGENTS.md
---

# Validate Image Updates

This skill provides the authoritative 6-step workflow for ensuring system integrity during image updates.

## Mandatory Sequential Workflow

When a new image build is triggered or the codebase is modified, agents MUST follow this sequence:

1.  **Stop Workstation**: Ensure the target instance is in `STATE_STOPPED` to prevent hot-patching drift.
2.  **Run Local Tests**: Execute `./scripts/run_local_tests.sh` from the skill directory. This runs linters, unit tests, and frontend build checks.
3.  **Monitor Build**: If local tests pass, wait for the Cloud Build to reach `SUCCESS`.
4.  **Start Workstation**: Only after a successful build.
5.  **Run Integration Tests**: Execute `./scripts/run_integration_tests.sh` on the live instance to verify service orchestration.
6.  **Persona Reviews**: Conduct in-depth reviews (UX, SEC, SRE, etc.) once the system is live.

## Technical Health Check

Technical health is verified by ensuring all tests in the `validate-image-updates` suite pass before starting the workstation.

## Integration Dependencies

This skill depends on the correct configuration of the `gcloud` CLI and access to the Cloud Workstations API.
