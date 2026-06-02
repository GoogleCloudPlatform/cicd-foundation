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

"""Validation utility for the Software Bill of Materials (SBOM) and its assets."""

import json
import sys
from pathlib import Path
from typing import Dict


def validate_manifest(sbom_path_str: str) -> None:
    """Checks if manifest exists, is valid JSON, and has required metadata.

    Args:
        sbom_path_str: Path to the JSON SBOM file.
    """
    sbom_path = Path(sbom_path_str)
    try:
        with sbom_path.open("r", encoding="utf-8") as f:
            data = json.load(f)
            meta = data.get("metadata", {})
            required = ["project", "copyright", "organization", "repository", "url"]
            for field in required:
                if field not in meta:
                    print(f"error: missing metadata field: {field}", file=sys.stderr)
                    sys.exit(1)
    except Exception as e:
        print(f"error: manifest validation failed: {e}", file=sys.stderr)
        sys.exit(1)


def validate_assets(sbom_path_str: str, assets_root_str: str) -> None:
    """Checks if all unique licenses in SBOM have valid local files.

    Args:
        sbom_path_str: Path to the JSON SBOM file.
        assets_root_str: Path to the directory containing local license assets.
    """
    sbom_path = Path(sbom_path_str)
    assets_root = Path(assets_root_str)

    # go/keep-sorted start
    signatures: Dict[str, str] = {
        "Apache-2.0": "Apache License",
        "BSD-2-Clause": "Redistributions in binary form",
        "GPL-2.0-only": "GNU GENERAL PUBLIC LICENSE",
        "MIT": "Permission is hereby granted",
    }
    # go/keep-sorted end

    try:
        with sbom_path.open("r", encoding="utf-8") as f:
            data = json.load(f)
            licenses = data.get("licenses", {})

            for lid, info in licenses.items():
                local_path_str = info["local_text"].lstrip("/")
                asset_path = assets_root / local_path_str

                if not asset_path.is_file():
                    print(
                        f"error: missing asset for {lid}: {asset_path}", file=sys.stderr
                    )
                    sys.exit(1)

                if asset_path.stat().st_size == 0:
                    print(
                        f"error: empty asset for {lid}: {asset_path}", file=sys.stderr
                    )
                    sys.exit(1)

                with asset_path.open("r", encoding="utf-8") as tf:
                    content = tf.read().lower()

                    # 404 Check
                    if "404" in content and "not found" in content:
                        print(
                            f"error: asset for {lid} is a 404 page: {asset_path}",
                            file=sys.stderr,
                        )
                        sys.exit(1)

                    # Signature Check
                    sig = signatures.get(lid, "").lower()
                    if sig and sig not in content:
                        print(
                            f"error: asset for {lid} missing signature '{sig}': {asset_path}",
                            file=sys.stderr,
                        )
                        sys.exit(1)

            # Integrity Check: Ensure components reference valid IDs
            for comp in data.get("components", []):
                if comp.get("license_id") not in licenses:
                    print(
                        f"error: component {comp['name']} unknown license: {comp['license_id']}",
                        file=sys.stderr,
                    )
                    sys.exit(1)

    except Exception as e:
        print(f"error: asset validation failed: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(
            "usage: sbom_validator.py <action:manifest|assets> <sbom_path> [assets_root]",
            file=sys.stderr,
        )
        sys.exit(1)

    action = sys.argv[1]
    path_arg = sys.argv[2]

    if action == "manifest":
        validate_manifest(sbom_path_str=path_arg)
    elif action == "assets":
        root_arg = sys.argv[3] if len(sys.argv) > 3 else str(Path(path_arg).parent)
        validate_assets(sbom_path_str=path_arg, assets_root_str=root_arg)
    else:
        print(f"error: unknown action: {action}", file=sys.stderr)
        sys.exit(1)
