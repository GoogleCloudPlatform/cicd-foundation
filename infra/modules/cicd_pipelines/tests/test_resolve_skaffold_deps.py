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

"""Unit tests for the recursive Skaffold dependency resolver script."""

import os
import sys
import tempfile
import unittest

sys.path.append(os.path.join(os.path.dirname(__file__), "../scripts"))
from resolve_skaffold_deps import get_transitive_deps, parse_requires_from_yaml, resolve_query


def _create_skaffold_config(dir_path: str, requires_paths: list[str] | None = None) -> None:
    """Helper to generate a mock skaffold.yaml file."""
    os.makedirs(dir_path, exist_ok=True)
    config_path = os.path.join(dir_path, "skaffold.yaml")
    lines = ["apiVersion: skaffold/v3", "kind: Config"]
    if requires_paths:
        lines.append("requires:")
        for path in requires_paths:
            lines.append(f"  - path: {path}")
    with open(config_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


class TestResolveSkaffoldDeps(unittest.TestCase):
    """Test suite for recursive dependency resolution and parser utilities."""

    def test_get_transitive_deps_returns_self_glob_for_standalone_app(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            _create_skaffold_config(os.path.join(tmpdir, "apps/standalone"))
            deps = get_transitive_deps("apps/standalone", tmpdir)
            self.assertEqual(deps, ["apps/standalone/**"])

    def test_get_transitive_deps_resolves_multi_tier_hierarchy(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            # Build hierarchy: leaf -> mid -> root
            _create_skaffold_config(
                os.path.join(tmpdir, "apps/workstations/leaf"),
                requires_paths=["../mid/skaffold.yaml"],
            )
            _create_skaffold_config(
                os.path.join(tmpdir, "apps/workstations/mid"),
                requires_paths=["../root/skaffold.yaml"],
            )
            _create_skaffold_config(os.path.join(tmpdir, "apps/workstations/root"))

            deps = get_transitive_deps("apps/workstations/leaf", tmpdir)
            expected = [
                "apps/workstations/leaf/**",
                "apps/workstations/mid/**",
                "apps/workstations/root/**",
            ]
            self.assertEqual(deps, expected)

    def test_get_transitive_deps_handles_circular_dependencies_gracefully(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            _create_skaffold_config(
                os.path.join(tmpdir, "apps/a"),
                requires_paths=["../b/skaffold.yaml"],
            )
            _create_skaffold_config(
                os.path.join(tmpdir, "apps/b"),
                requires_paths=["../a/skaffold.yaml"],
            )

            deps = get_transitive_deps("apps/a", tmpdir)
            self.assertEqual(set(deps), {"apps/a/**", "apps/b/**"})

    def test_get_transitive_deps_handles_missing_file_gracefully(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            # Directory without a skaffold.yaml
            os.makedirs(os.path.join(tmpdir, "apps/nonexistent"), exist_ok=True)
            deps = get_transitive_deps("apps/nonexistent", tmpdir)
            self.assertEqual(deps, ["apps/nonexistent/**"])

    def test_parse_requires_from_yaml_with_quotes_and_comments(self):
        yaml_content = """
    apiVersion: skaffold/v3
    # Comment line
    requires:
      - path: '../codeoss/skaffold.yaml' # inline comment
      - path: "../common/skaffold.yaml"
    build:
      artifacts: []
    """
        paths = parse_requires_from_yaml(yaml_content)
        self.assertEqual(paths, ["../codeoss/skaffold.yaml", "../common/skaffold.yaml"])

    def test_resolve_query_generates_valid_terraform_payload(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            _create_skaffold_config(
                os.path.join(tmpdir, "apps/workstations/codeoss"),
                requires_paths=["../common/skaffold.yaml"],
            )
            _create_skaffold_config(os.path.join(tmpdir, "apps/workstations/common"))

            result = resolve_query(
                {
                    "skaffold_path": "apps/workstations/codeoss",
                    "repo_root": tmpdir,
                }
            )
            expected_included = "apps/workstations/codeoss/**,apps/workstations/common/**"
            self.assertEqual(result, {"included_files": expected_included})


if __name__ == "__main__":
    unittest.main()
