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

# Test Plan: Cloud Workstations Custom Image Automation

## 1. Overview

This document defines the testing strategy for the Cloud Workstations custom image automation project. The goal is to verify that all functional and non-functional requirements defined in the PRD are met through a combination of automated and manual validation.

## 2. Testing Strategy

We follow the standard Testing Pyramid, focusing on fast-running unit tests for logic and comprehensive integration tests for system-level behavior.

### 2.1 Test Levels

- **Unit Tests**: Verify individual scripts, hooks, and configuration templates in isolation.
- **Integration Tests**: Verify the behavior of a live containerized workstation instance using Bats.
- **Manual/E2E Verification**: Final human-in-the-loop verification of the graphical session and user experience.

## 3. Verification of Acceptance Criteria

### AC1: Nightly builds configured via cicd-foundation

- **Verification**:
  - Inspect Terraform state/output to confirm `google_cloud_scheduler_job` and `google_cloudbuild_trigger` resources are created.
  - Manual check in the Google Cloud Console to verify the trigger is linked to the nightly scheduler.

### AC2: Images can be deployed and reached via browser

- **Verification**:
  - **Automated**: `test_rdp_connection.bats` verifies that the RDP port is open and reachable.
  - **Manual**: Perform a "Persona Review" by opening the workstation in a Chrome browser and interacting with the GNOME desktop.

### AC3: Integration tests pass for 100% of core service health checks

- **Verification**:
  - Execute `skills/validate-image-updates/scripts/run_integration_tests.sh`.
  - Specific test files:
    - `test_cws_services.bats`: Checks systemd services (Nginx, Guacamole, GNOME).
    - `test_docker_dind.bats`: Verifies the internal Docker daemon for Guacamole.
    - `test_user_permissions.bats`: Ensures the workstation user has the correct environment.

### AC4: Documentation is complete and sufficient

- **Verification**:
  - **Technical Review**: Peer review of `README.md`, `docs/deployment_guide.md`, and style guides.
  - **User Trial**: A "clean room" deployment by a user not involved in development (e.g., a Developer Advocate persona).

## 4. Non-Functional Requirement (NFR) Validation

### 4.1 Availability (99.9% SLO)

- **Method**: While CI tests verify 100% success in a controlled environment, long-term availability is monitored via Cloud Logging.
- **Test**: Verify that `config-rendering` and `workstation-startup` services log "READY" markers within the expected timeframe.

### 4.2 Performance (<200s Startup)

- **Method**: The integration test suite will record the duration from container start to Guacamole readiness.
- **Benchmark**: If a build consistently exceeds 200s on an `e2-standard-8` machine, it is considered a performance regression.

## 5. Test Environment

- **Infrastructure**: GCP Project with Cloud Workstations API enabled.
- **Base Layer**: The `Preflight` image must be pre-built and available in the Artifact Registry.
- **Local Tools**: `skaffold`, `bats-core`, and `gcloud`.

## 6. Execution Gating (Agentic Mandate)

As per `AGENTS.md`, every change must pass the following sequence:

1.  `scripts/run_local_tests.sh` (Unit & Lint)
2.  Full Cloud Build (Image Creation)
3.  `run_integration_tests.sh` (Bats on live instance)
