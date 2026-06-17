# AI Agent Instructions: Antigravity 2.0 Layer

Specific mandates for the Antigravity 2.0 application environment.

## 1. Application Engineering Standards

- **GPU Bypassing**: Always utilize the `/usr/local/bin/antigravity` wrapper to launch the application with `--disable-gpu` to ensure stability in headless environments.
- **Autostart Stability**: The application startup wrapper MUST utilize the centralized `wait_for_monitor` utility from the GNOME layer to ensure graphics environment readiness.
- **UX Integration**: Application registration (favorites, autostart) must be performed via the centralized `desktop_integration.sh` utility in a post-install hook.

## 2. Mandatory Testing

Verify the application and dashboard:

```bash
skills/validate-image-updates/scripts/run_integration_tests.sh
```

---

👉 **[GNOME Foundation](../gnome/AGENTS.md)**
