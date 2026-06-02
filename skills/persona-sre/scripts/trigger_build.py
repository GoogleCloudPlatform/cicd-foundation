#!/usr/bin/env python3

# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Triggers a manual Cloud Build using production trigger logic.

This script leverages existing Terraform-managed triggers by downloading their
definition, adapting it for local source upload (removing the clone step),
and submitting it.
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List


def log(msg: str) -> None:
    """Logs an informational message to stdout."""
    print(f"[\033[0;34mLOG\033[0m] {msg}")


def warn(msg: str) -> None:
    """Logs a warning message to stdout."""
    print(f"[\033[0;33mWARN\033[0m] {msg}")


def error(msg: str) -> None:
    """Logs an error message to stderr and exits."""
    # i18n: Technical error strings should be lowercase and have no punctuation.
    print(f"[\033[0;31mERROR\033[0m] {msg}", file=sys.stderr)
    sys.exit(1)


def run_command(
    cmd: List[str], capture_output: bool = True
) -> subprocess.CompletedProcess:
    """Runs a shell command and returns the completed process."""
    try:
        return subprocess.run(cmd, check=True, capture_output=capture_output, text=True)
    except subprocess.CalledProcessError as e:
        if capture_output:
            return e
        raise


def get_env_vars() -> Dict[str, str]:
    """Reads environment variables from .env if present.

    Environment variables already set in the system take precedence over the
    .env file.

    Returns:
        A dictionary of environment variables.
    """
    env_vars = {}
    # Repo root is 3 levels up from this script (scripts/trigger_build.py)
    repo_root = Path(__file__).resolve().parents[3]
    env_file = repo_root / ".env"

    if env_file.exists():
        with env_file.open("r") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if "=" in line:
                    key, value = line.split("=", 1)
                    env_vars[key.strip()] = value.strip().strip("'\"")

    # System environment variables take precedence
    keys = [
        # go/keep-sorted start
        "ARTIFACT_REGION",
        "BUILD_REGION",
        "PROJECT",
        # go/keep-sorted end
    ]
    for key in keys:
        if key in os.environ:
            env_vars[key] = os.environ[key]

    return env_vars


def adapt_config(trigger_json: Dict[str, Any]) -> Dict[str, Any]:
    """Surgically adapts a trigger's build config for local source upload.

    Args:
        trigger_json: The raw JSON definition of the Cloud Build trigger.

    Returns:
        A dictionary representing the adapted build configuration.
    """
    build = trigger_json.get("build", {})
    if not build:
        error("trigger definition does not contain a build configuration")

    steps = build.get("steps", [])

    # Remove the 'clone' step as we are uploading local sources
    new_steps = [step for step in steps if step.get("id") != "clone"]

    # Update 'waitFor' dependencies to remove references to the deleted clone step
    for step in new_steps:
        wait_for = step.get("waitFor", [])
        if wait_for:
            step["waitFor"] = [w for w in wait_for if w != "clone"]

    # Preserve essential build options and timeout
    adapted_build = {
        "steps": new_steps,
        "options": build.get("options", {}),
        "timeout": build.get("timeout", "7200s"),
    }

    return adapted_build


def main():
    """Main entry point for the trigger script."""
    parser = argparse.ArgumentParser(
        description="Trigger a manual Cloud Build using production trigger logic."
    )
    parser.add_argument(
        "image_path",
        nargs="?",
        default="apps/workstations/gnome",
        help="Path to the image directory.",
    )
    parser.add_argument(
        "--service-account", help="Override the service account for the build."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Display the adapted build configuration without submitting.",
    )
    args = parser.parse_args()

    # Path Validation
    image_path = Path(args.image_path)
    if not image_path.is_dir():
        error(f"image path does not exist or is not a directory: {args.image_path}")

    if not (image_path / "Dockerfile").exists():
        error(f"image directory must contain a dockerfile: {args.image_path}")

    env = get_env_vars()
    project = env.get("PROJECT")
    region = env.get("BUILD_REGION")
    artifact_repo = env.get("ARTIFACT_REGION")

    if not project or not region:
        error("PROJECT and BUILD_REGION must be set in .env or environment")

    image_name = image_path.name
    repo_root = Path(__file__).resolve().parents[3]

    log("======================================")
    log(f" 🚀 Triggering Cloud Build for {image_name}")
    log("======================================")
    log(f"Project:    {project}")
    log(f"Region:     {region}")
    log(f"Image Path: {args.image_path}")
    log("======================================")

    substitutions = {}
    service_account = args.service_account

    log(f"Searching for existing trigger: {image_name}...")
    try:
        result = run_command(
            [
                "gcloud",
                "builds",
                "triggers",
                "describe",
                image_name,
                f"--project={project}",
                f"--region={region}",
                "--format=json",
            ]
        )
        trigger_data = json.loads(result.stdout)
        log("✅ Found existing trigger. Adapting configuration...")

        build_config = adapt_config(trigger_data)

        # Inherit user-defined substitutions (starting with _)
        for k, v in trigger_data.get("substitutions", {}).items():
            if k.startswith("_"):
                substitutions[k] = v

        # Inherit service account from trigger if not explicitly overridden
        if not service_account:
            service_account = trigger_data.get("serviceAccount")
            if service_account:
                # Strip 'projects/*/serviceAccounts/' prefix if present
                service_account = service_account.split("/")[-1]

    except subprocess.CalledProcessError:
        warn(
            f"Trigger '{image_name}' not found. Falling back to minimal configuration."
        )
        build_config = {
            "options": {
                "logging": "CLOUD_LOGGING_ONLY",
                "machineType": "E2_HIGHCPU_32",
            },
            "timeout": "7200s",
            "steps": [
                {
                    "name": "gcr.io/k8s-skaffold/skaffold:v2.18.1",
                    "id": "build",
                    "entrypoint": "/bin/sh",
                    "args": [
                        "-c",
                        "skaffold build --default-repo=$_SKAFFOLD_DEFAULT_REPO "
                        "--interactive=false --cache-artifacts=true",
                    ],
                    "dir": args.image_path,
                    "env": [
                        f"CWS_BASE_IMAGE_TAG={os.environ.get('CWS_BASE_IMAGE_TAG', 'latest')}",
                        f"GCP_REGION={os.environ.get('GCP_REGION', 'us-central1')}",
                        "INTERNAL_REGISTRY=$_SKAFFOLD_DEFAULT_REPO",
                    ],
                }
            ],
        }
        fallback_repo = artifact_repo or region
        substitutions["_SKAFFOLD_DEFAULT_REPO"] = (
            f"{fallback_repo}-docker.pkg.dev/{project}/cicd-foundation"
        )

    # Apply critical overrides for local context
    substitutions["_SKAFFOLD_PATH"] = args.image_path
    substitutions["_IMAGE_PATH"] = args.image_path

    if not service_account:
        service_account = f"cloudbuild@{project}.iam.gserviceaccount.com"

    if args.dry_run:
        log("DRY-RUN: Adapted build configuration:")
        print(json.dumps(build_config, indent=2))
        log("DRY-RUN: Substitutions:")
        print(json.dumps(substitutions, indent=2))
        return

    log(f"Submitting build with service account: {service_account}")

    subst_str = ",".join([f"{k}={v}" for k, v in substitutions.items()])

    # Submit the build with local source and the adapted config via stdin
    submit_cmd = [
        "gcloud",
        "builds",
        "submit",
        str(repo_root),
        f"--project={project}",
        f"--region={region}",
        f"--service-account=projects/{project}/serviceAccounts/{service_account}",
        f"--substitutions={subst_str}",
        "--config=-",
    ]

    try:
        subprocess.run(
            submit_cmd, input=json.dumps(build_config), text=True, check=True
        )
    except subprocess.CalledProcessError as e:
        error(f"build submission failed with exit code {e.returncode}")


if __name__ == "__main__":
    main()
