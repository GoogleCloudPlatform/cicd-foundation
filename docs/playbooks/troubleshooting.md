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

# Cloud Workstations (CWS) Troubleshooting Playbook

This playbook defines the standardized process for diagnosing and resolving issues within the custom GNOME-based Cloud Workstations image. The architecture is complex, relying on intricate systemd dependency graphs, nested Docker containers, and headless Wayland displays.

Therefore, ad-hoc debugging should be avoided. Follow this process linearly.

## Phase 1: Automated Initial Assessment

Before attempting to SSH into the instance or reading raw journal logs, you must execute the automated integration test suite. This suite is specifically designed to isolate failures within the dependency chain.

### 1. Configure the Environment

Ensure your connection details are configured. The tests require an active Workstation instance.

```bash
cp .env.example .env
# Edit .env to include your PROJECT, CLUSTER, CONFIG, REGION, and WORKSTATION names.
```

### 2. Execute the Suite

Run the primary test script from the root of the repository:

```bash
./skills/validate-image-updates/scripts/run_all_tests.sh
```

This script will execute:

1.  **Unit Tests**: Local validation of bash library functions.
2.  **Integration Tests**: Remote validation of the live instance via `gcloud workstations ssh`.

## Phase 2: Analyzing the Results & Targeted Diagnosis

Analyze the output of the integration tests to determine the failure domain.

### Scenario A: `test_cws_services.sh` Fails

If a core service (like `nginx`, `workstation-startup`, or `gnome-session@user`) fails to start or is missing a network listener:

1.  **Check Systemd Cycles**: This is often caused by an ordering cycle in systemd unit overrides.
    - Command: `sudo journalctl -b | grep -i cycle`
2.  **Check Service Logs**: Look at the specific failing service.
    - Command: `sudo journalctl -u <failing_service>.service --no-pager -n 50`

### Scenario B: `test_user_permissions.sh` Fails

If this test fails, the GNOME desktop environment will almost certainly crash.

1.  **Check Ephemeral Password**: Ensure `/tmp/workstation/ephemeral.env` exists and is strictly `640 root:1000`. If it's missing, `config-rendering.service` either failed or was wiped by systemd's tmpfs mount (check dependencies).
2.  **Check Headless Shell**: If `gnome-shell` is running without the `--headless` flag, it will crash immediately. Ensure the systemd drop-in override (`assets/etc/systemd/user/org.gnome.Shell@wayland.service.d/override.conf`) is being successfully copied to the instance.

### Scenario C: `test_nginx_config.sh` Fails

If Nginx is unreachable or returns a 502/503:

1.  **Check Handover**: If Nginx is serving on 127.0.0.1 but external access is still blocked, `permit-traffic.service` might have failed its probe. Check its status: `sudo systemctl status permit-traffic`.
2.  **Check Rendering**: If the test reports that placeholders still exist, `config-rendering.service` did not complete successfully.
3.  **Check Guacamole Backend**: If Nginx returns 502, it means the `guacamole` Docker container is dead or still starting. Check its logs: `sudo docker logs guacamole`.

### Scenario D: `test_rdp_connection.sh` Fails

This test bypasses Guacamole and uses `xfreerdp` locally to test the GNOME Remote Desktop daemon directly. If it fails:

1.  **Check GNOME Logs**: The daemon likely rejected the credentials. Check the user's journal for MIC (Message Integrity Check) or NLA (Network Level Authentication) failures.
    - Command: `sudo journalctl _UID=1000 | grep -iE 'MIC|transport_accept_nla'`
2.  **Verify Synchronization**: Ensure `grdctl` was successfully executed _before_ the daemon started.

### Scenario E: `test_guacamole_config.sh` Fails

If this fails, the credentials in the `user-mapping.xml` do not match the `ephemeral.env` password, or the XML failed to render.

1.  **Check Service Ordering**: Ensure `guacamole.service` and `nginx.service` both explicitly `Wait` for and run `After=config-rendering.service`.

## Phase 3: Known Issues & Architecture Gotchas

- **FreeRDP 3.x / NLA MIC Verification**: GNOME 46 Remote Desktop strictly mandates NLA security. Apache Guacamole 1.6.0 (which uses FreeRDP 3.x) is highly sensitive to NTLM hash mismatches. Ensure RDP credentials are fully configured before starting the `gnome-remote-desktop-daemon`.
- **Wayland Shell Overrides**: Modern GNOME ignores `.desktop` files for its primary shell. To force a headless Wayland virtual monitor, you **must** use a systemd user drop-in (`org.gnome.Shell@wayland.service.d/override.conf`). Attempting to run `gnome-session --session=ubuntu` alongside a manually backgrounded `gnome-shell` will result in a D-Bus conflict and a fatal crash.
- **PAM Lastlog Error**: A `PAM unable to dlopen(pam_lastlog.so)` error is purely cosmetic in this Ubuntu minimal image and is safe to ignore. It does not affect functionality.
