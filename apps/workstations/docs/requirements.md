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

# Product Requirements Document: Cloud Workstations Custom Image Automation

## 1. Project Overview

### 1.1 Objective

Simplify and automate the deployment of Google Cloud Workstations (CWS) using customized container images. This project provides a robust, secure GNOME-based Remote Desktop environment and a standardized CI/CD pipeline.

### 1.2 Target Personas

- **External Customers**: Deploying standardized, secure VDI-like environments.
- **Googlers (CE/DA/SCE)**: Utilizing images for high-impact demos and hackathons.
- **SRE/Platform Engineers**: Managing the image lifecycle and automation foundation.

## 2. Functional Requirements (The "What")

- **FR1: GNOME Desktop Environment**: Provide a headless Wayland-based GNOME session.
- **FR2: Browser-Based Access**: Enable RDP access via a web gateway (Apache Guacamole) without local client requirements.
- **FR3: Automated Lifecycle**: Full automation for building, testing, and pushing images.
- **FR4: Image Freshness**: Support for automated nightly rebuilds to incorporate upstream security patches.

## 3. Non-Functional Requirements (The "How Well")

### 3.1 Availability & Reliability (SLO)

- **Service Availability**: Core internal services (Nginx, Guacamole, GNOME) must achieve a **99.9% success rate** for initialization post-container start.
- **Observability**: Availability must be measurable via Cloud Logging and Monitoring (tracing service start events).
- _Note: GCE/CWS infrastructure availability is out of scope._

### 3.2 Performance

- **Startup Latency**: The remote desktop backend must be reachable and ready for connection within **200 seconds** for 99.9% of starts (assuming recommended machine types).

### 3.3 Security

- **Ephemeral Credentials**: RDP passwords must be generated per-start, injected dynamically, and never persisted to non-volatile storage.
- **Software Rendering**: Force `LIBGL_ALWAYS_SOFTWARE=1` to ensure stability across GPU-less machine types.

## 4. Technical Constraints (The "Given")

- **CI/CD Foundation**: Automation MUST be realized through the `cicd-foundation` Terraform module(s).
- **Service Management**: All container services MUST be managed via native Systemd unit files.
- **Parent Image**: Must build upon the established `Preflight` layer for gateway and credential orchestration.

## 5. Acceptance Criteria (The "When are we done?")

- **AC1**: Nightly builds are successfully configured via Cloud Scheduler and `cicd-foundation`.
- **AC2**: Verified that images can be deployed to a CWS configuration and reached via browser.
- **AC3**: Integration tests (Bats) pass for 100% of core service health checks in the CI pipeline.
- **AC4**: Documentation (README/Guides) is complete and sufficient for a new user to deploy the solution.

## 6. Validation Strategy (Development Lifecycle)

_Detailed verification steps required during development as per AGENTS.md._

- **Agentic/Manual Workflow**: All changes during development MUST follow the mandatory 6-step workflow (Stop, Local Test, Build, Start, Integration Test, Persona Review).
- **Local Validation**: Mandatory execution of `scripts/run_local_tests.sh` before finalizing changes.
- **Integration Testing**: Automated Bats suite running on a live workstation instance to confirm behavioral correctness.
