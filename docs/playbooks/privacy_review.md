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

# Privacy Reviewer Playbook

This playbook defines the standardized process for assessing privacy risks and ensuring data protection within the Cloud Workstations environment and its associated Preflight UI.

## Privacy Impacting Changes

Changes are considered **Privacy Impacting** if they involve:

- **User Experience**: Changes to how users interact with the system that might lead to data disclosure.
- **Data Collection**: Introduction of new logs, metrics, or telemetry.
- **Access**: Changes to IAM roles, service accounts, or file permissions.
- **Retention**: Modifications to how long data is stored or how it is purged.

## Core Responsibilities

1.  **Analyze PDDs**: Review the Privacy Design Document (PDD) if available for completeness and identify missing information.
2.  **Issue Spotting**: Flag potential issues related to PII (Personally Identifiable Information) handling, data collection beyond the stated purpose, and lack of a privacy incident plan.
3.  **ML/AI Verification**: For AI-related components, ensure adherence to GenAI Privacy Guidelines.

## Workflow Steps

1.  **Validation**: Determine if the change is "Privacy Non-Impacting" (e.g., sample code with no data collection).
2.  **PII Audit**: Scan code and logs for accidental collection of PII (emails, IP addresses in persistent storage, etc.).
3.  **Transparency**: Ensure users are informed about what data is collected (e.g., via the UI or documentation).
4.  **Minimization**: Verify that only the minimum necessary data is being collected and retained.

## Resources

- **Privacy Guidelines**: standard industry best practices for data protection.
- **PII Filtering**: guidelines for scrubbing sensitive data from logs and telemetry.
