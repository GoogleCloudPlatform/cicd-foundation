---
name: update-preflight
description: Manages preflight web app UX/UI constraints, layout stability, and the frontend hot-patching deployment process. Use when modifying HTML, CSS, or JS in the apps/workstations/preflight-web/ directory.
license: Apache-2.0
allowed-tools: apps/workstations/preflight/skills/update-preflight/scripts/hotpatch_frontend.sh apps/workstations/preflight/skills/update-preflight/scripts/test_and_hotpatch.sh
metadata:
  author: sce-taid <sce@taid.me>
  resources:
    - apps/workstations/preflight/docs/design.md
    - apps/workstations/preflight/docs/requirements.md
---

# Update Cloud Workstations Frontend

This skill manages the updates to the preflight web UI and ensures adherence to the repository's UX/UI standards.

## UX/UI Standards

When modifying the frontend, you MUST strictly adhere to the authoritative UX/UI standards:
👉 **[Authoritative UX/UI Standards](../../docs/design.md)**

## Frontend Hot-patching Workflow

When modifying the preflight page or other web assets in the `apps/workstations/preflight-web/` directory, use the following hot-patch script to provide immediate feedback on the live instance:

1.  **Execute**: Run `./scripts/test_and_hotpatch.sh` from the skill directory.
2.  **What it does**: This script automatically runs the frontend test suite via Vitest (`npm test`). If successful, it builds the frontend assets via Vite (`npm run build`) and syncs the `apps/workstations/preflight-web/dist/` directory to `/var/www/html/` on your active workstation.
3.  **Validate**: Refresh the browser and verify changes immediately on the live instance before concluding the task.
