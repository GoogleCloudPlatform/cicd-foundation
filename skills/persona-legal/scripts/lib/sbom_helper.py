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

"""Helper utility for parsing the Software Bill of Materials (SBOM) manifest."""

import json
import sys
from pathlib import Path


def get_license_mappings(sbom_path_str: str) -> None:
    """Extracts unique license URLs and their local target paths from an SBOM.

    This function parses the JSON SBOM and prints space-separated strings
    in the format "lid url local_text" to stdout, which are consumed by
    downstream bash scripts.

    Args:
        sbom_path_str: The string path to the JSON SBOM file.
    """
    sbom_path = Path(sbom_path_str)
    if not sbom_path.exists():
        print(f"error: SBOM not found at {sbom_path}", file=sys.stderr)
        sys.exit(1)

    try:
        with sbom_path.open("r", encoding="utf-8") as f:
            data = json.load(f)
            licenses = data.get("licenses", {})
            for lid, info in licenses.items():
                url = info.get("url")
                local_text = info.get("local_text")
                if url and local_text:
                    # We print space separated values for the bash script to consume
                    print(f"{lid} {url} {local_text}")
    except json.JSONDecodeError as e:
        print(f"error: failed to parse SBOM JSON: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"error: unexpected error parsing SBOM: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: sbom_helper.py <sbom_json_path>", file=sys.stderr)
        sys.exit(1)
    get_license_mappings(sys.argv[1])
