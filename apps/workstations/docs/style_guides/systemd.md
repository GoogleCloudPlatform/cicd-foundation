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

# Systemd Configuration Style Guide

This project relies heavily on `systemd` to orchestrate background services, startup ordering, and application lifecycles. Strict adherence to systemd best practices ensures the environment boots predictably and cleanly.

## Key Principles

1. **Explicit Dependencies**: Use `Wants=` and `After=` carefully. Do not create ordering cycles. Remember that `Wants=` only means "start these too", but `After=` actually enforces the "wait for this to finish starting" behavior.
2. **Declarative Enablement**: Avoid manual symlink management in the `assets/` directory. Instead, use a systemd target drop-in (e.g., `multi-user.target.d/10-workstation.conf`) and the `Wants=` directive to centrally define active services.
3. **Conditional Execution**: For services that depend on environment variables (like optional features), use `ConditionEnvironment=VARIABLE=true`. This allows the service to be "enabled" in the manifest while systemd handles skipping it automatically based on the environment.
4. **Avoid Loops in ExecStartPre**: Never use `ExecStartPre` to poll or loop waiting for a condition (e.g., `while ! curl ...`). Instead, rely on native systemd dependencies (`After=other-service.service`) or `Type=notify`.
5. **Type=simple vs Type=notify**: Use `Type=simple` for services that run continuously in the foreground. If a service needs to signal readiness before dependents start, use `Type=notify` and ensure the application sends the `READY=1` sd_notify signal.
6. **Environment Variables**: For dynamic configuration, rely on `EnvironmentFile=` or dynamic rendering scripts that execute in `ExecStartPre`. Use `DefaultEnvironment=` in the manager configuration to propagate variables from Docker.

## Environment Propagation

In containerized environments, environment variables defined in the `Dockerfile` or via `gcloud` are not automatically visible to the systemd manager (PID 1).

1.  **Manager Configuration**: Use `/etc/systemd/system.conf.d/*.conf` with a `[Manager]` section and the `DefaultEnvironment=` directive to make variables available to all units.
2.  **Explicit Capture**: Use a startup script (e.g., `start_systemd.sh`) to capture relevant `ENABLE_*` variables from the shell environment and write them to the manager configuration before starting `init`.
3.  **Conditionals**: Once propagated, these variables can be used for `ConditionEnvironment=` checks, allowing for clean, declarative service enablement.

## Naming Conventions

To maintain a clear separation between system orchestration and script logic, this project implements the following naming standards:

1. **Unit Filenames (Hyphens)**: All systemd unit files (`.service`, `.socket`, `.path`) must use hyphens (`-`) for word separation.
   - Example: `config-rendering.service`, `workstation-startup.service`.
2. **Backing Scripts (Underscores)**: Shell scripts executed by these units (usually located in `/google/scripts/`) must use underscores (`_`) for word separation, as per the [Bash Style Guide](bash.md).
   - Example: `config_rendering.sh`, `user_setup.sh`.

## Testing Systemd Configurations

Testing systemd units is done via our integration test suite using **Bats-core**.

### How to Write Tests

When adding or modifying a systemd service, you MUST write an integration test.

1. **Service State**: Check that the service is actually active.
   ```bash
   @test "My Service is active" {
     run run_ssh "sudo systemctl is-active my-service.service --quiet"
     [ "$status" -eq 0 ]
   }
   ```
2. **Log Verification**: Ensure the service didn't log fatal errors or crash loops.
   ```bash
   @test "My Service started without errors" {
     run run_ssh "sudo journalctl -u my-service.service --no-pager | grep -qi 'error|fail'"
     [ "$status" -eq 1 ] # Expecting NO matches
   }
   ```
3. **Behavioral Checks**: Beyond just `systemctl is-active`, test the actual behavior (e.g., "Is the port listening?", "Is the socket file created?", "Is the process actually in `ps aux`?").
