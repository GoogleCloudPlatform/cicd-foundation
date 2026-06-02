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

# Cloud Workstations Preflight Module

Web-based loading experience for Google Cloud Workstations.

## Features

### Phased Monitoring State Machine

```mermaid
stateDiagram-v2
    [*] --> NominalPhase: Startup
    NominalPhase --> NominalPhase: Poll (1s)
    NominalPhase --> TimeoutPhase: Elapsed > Timeout
    NominalPhase --> ReadyState: Success
    TimeoutPhase --> TimeoutPhase: Poll (Backoff)
    TimeoutPhase --> ReadyState: Success
    ReadyState --> [*]: Redirect (autoRedirect=true)
```

### Built-in Simulation

Test behavior using URL parameters:

- `?simulateDelay=15`: Simulate 15s startup.
- `?autoRedirect=false`: Pause at the READY screen.
- `?timeout=10`: Start backoff after 10s.

## Documentation

The Preflight layer documentation is organized into two authoritative documents:

- 👉 **[Product Requirements (PRD)](docs/requirements.md)**: Mandates and user personas.
- 👉 **[Design Document (DD)](docs/design.md)**: Architectural specifications and operational playbooks.

---

Brought to you by the Google Cloud Professional Services Organization Apps team (PSO AppΣ)
