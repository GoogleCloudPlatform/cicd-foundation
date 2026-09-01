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

"""Recursively resolves transitive dependencies from skaffold.yaml files.

This script is invoked by Terraform's `data "external"` provider to discover
transitive filesystem dependencies across Cloud Workstation custom images and
devcontainer layers.

Input Protocol (via stdin JSON):
  {
    "skaffold_path": "apps/workstations/codeoss",
    "repo_root": "/path/to/repo/root"
  }

Output Protocol (via stdout JSON):
  {
    "included_files": "apps/workstations/codeoss/**,apps/workstations/common/**,apps/workstations/preflight/**"
  }
"""

import json
import os
import re
import sys
from collections import deque
from typing import Any

try:
    import yaml  # type: ignore[import-not-found,import-untyped]
except ImportError:
    yaml = None

_DEFAULT_REPO_ROOT: str = "."
_GLOB_SUFFIX: str = "/**"
_REQUIRES_PATH_PATTERN: re.Pattern[str] = re.compile(r"path:\s*['\"]?([^'\"\s#]+)['\"]?")
_SKAFFOLD_CONFIG_FILENAME: str = "skaffold.yaml"


def parse_requires_from_yaml(content: str) -> list[str]:
    """Extracts relative file paths from a skaffold.yaml 'requires:' block.

    Attempts to parse using PyYAML if installed; otherwise falls back to
    a lightweight regular expression parser to avoid third-party dependencies.

    Args:
      content: Raw string content of the skaffold.yaml file.

    Returns:
      A list of relative file path strings declared under the requires block.
    """
    if yaml is not None:
        try:
            data: dict[str, Any] = yaml.safe_load(content) or {}
            raw_requires: list[dict[str, Any]] = data.get("requires", []) or []
            return [req.get("path", "").strip() for req in raw_requires if isinstance(req, dict) and req.get("path")]
        except yaml.YAMLError:
            pass

    # Fallback: Line-by-line regex parser when PyYAML is unavailable
    extracted_paths: list[str] = []
    inside_requires_block: bool = False

    for line in content.splitlines():
        stripped_line = line.strip()
        if not stripped_line or stripped_line.startswith("#"):
            continue

        # Detect start of 'requires:' block
        if stripped_line.startswith("requires:"):
            inside_requires_block = True
            continue

        if inside_requires_block:
            # Exit block if a new unindented top-level key begins
            if not line.startswith(" ") and not line.startswith("\t"):
                inside_requires_block = False
                continue

            match = _REQUIRES_PATH_PATTERN.search(stripped_line)
            if match:
                extracted_paths.append(match.group(1).strip())

    return extracted_paths


def get_transitive_deps(skaffold_path: str, repo_root: str = _DEFAULT_REPO_ROOT) -> list[str]:
    """Performs Breadth-First Search over skaffold.yaml requires trees.

    Traverses parent references starting at `skaffold_path`, resolving all
    transitive layer dependencies and formatting them as glob patterns.

    Args:
      skaffold_path: Directory path of the application relative to repo root.
      repo_root: Absolute or relative path to the root of the repository.

    Returns:
      A list of directory glob patterns (e.g. `["apps/layer/**", ...]`) representing
      the target application and all its transitive ancestors.
    """
    visited_directories: set[str] = set()
    traversal_queue: deque[str] = deque([skaffold_path])
    resolved_glob_patterns: list[str] = []

    while traversal_queue:
        current_directory = traversal_queue.popleft()
        normalized_path = os.path.normpath(current_directory).lstrip("./")

        if not normalized_path or normalized_path in visited_directories:
            continue

        visited_directories.add(normalized_path)
        resolved_glob_patterns.append(f"{normalized_path}{_GLOB_SUFFIX}")

        target_yaml_path = os.path.join(repo_root, normalized_path, _SKAFFOLD_CONFIG_FILENAME)
        if not os.path.isfile(target_yaml_path):
            continue

        try:
            with open(target_yaml_path, "r", encoding="utf-8") as file_handle:
                file_content = file_handle.read()
                relative_paths = parse_requires_from_yaml(file_content)

                for relative_path in relative_paths:
                    parent_directory = os.path.normpath(os.path.join(normalized_path, os.path.dirname(relative_path)))
                    if parent_directory not in visited_directories and parent_directory not in traversal_queue:
                        traversal_queue.append(parent_directory)
        except OSError:
            # Gracefully continue if file read or permission errors occur
            continue

    return resolved_glob_patterns


def resolve_query(query: dict[str, str]) -> dict[str, str]:
    """Evaluates an external data query dictionary and generates output payload.

    Args:
      query: Key-value dictionary containing 'skaffold_path' and optional 'repo_root'.

    Returns:
      Dictionary containing the comma-separated 'included_files' result string.
    """
    skaffold_path = query.get("skaffold_path", "").strip()
    repo_root = query.get("repo_root", _DEFAULT_REPO_ROOT).strip()

    if not skaffold_path:
        return {"included_files": ""}

    dependencies = get_transitive_deps(skaffold_path, repo_root)
    return {"included_files": ",".join(dependencies)}


def main() -> None:
    """Main entrypoint for Terraform external provider invocation."""
    try:
        raw_input_data = sys.stdin.read().strip()
        query_payload = json.loads(raw_input_data) if raw_input_data else {}
    except (json.JSONDecodeError, OSError):
        query_payload = {}

    response = resolve_query(query_payload)
    sys.stdout.write(json.dumps(response) + "\n")


if __name__ == "__main__":
    main()
