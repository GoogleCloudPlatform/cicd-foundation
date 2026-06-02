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

"""Unit tests for the trigger_build script."""

import sys
import unittest
from pathlib import Path

# Add the scripts directory to sys.path to allow importing modules without packages
scripts_dir = Path(__file__).resolve().parents[1] / "scripts"
sys.path.append(str(scripts_dir))

from trigger_build import adapt_config


class TestTriggerBuild(unittest.TestCase):
    """Tests the configuration adaptation logic of trigger_build."""

    def test_adapt_config_removes_clone_step(self) -> None:
        """Verifies that the 'clone' step and its dependencies are removed."""
        # Mock trigger definition with a clone step and a build step waiting for it
        mock_trigger = {
            "build": {
                "steps": [
                    {
                        "id": "clone",
                        "name": "gcr.io/cloud-builders/git",
                        "args": ["clone", "..."],
                    },
                    {
                        "id": "build",
                        "name": "gcr.io/k8s-skaffold/skaffold",
                        "waitFor": ["clone"],
                        "args": ["build", "..."],
                    },
                    {
                        "id": "tag",
                        "name": "gcr.io/cloud-builders/docker",
                        "waitFor": ["build"],
                        "args": ["tag", "..."],
                    },
                ],
                "options": {"machineType": "E2_HIGHCPU_32"},
                "timeout": "3600s",
            }
        }

        adapted = adapt_config(mock_trigger)

        # Verify clone step is removed
        step_ids = [s.get("id") for s in adapted["steps"]]
        self.assertNotIn("clone", step_ids)
        self.assertEqual(len(adapted["steps"]), 2)

        # Verify build step no longer waits for clone
        build_step = next(s for s in adapted["steps"] if s["id"] == "build")
        self.assertNotIn("clone", build_step.get("waitFor", []))

        # Verify tag step still waits for build
        tag_step = next(s for s in adapted["steps"] if s["id"] == "tag")
        self.assertIn("build", tag_step.get("waitFor", []))

        # Verify options and timeout are preserved
        self.assertEqual(adapted["options"]["machineType"], "E2_HIGHCPU_32")
        self.assertEqual(adapted["timeout"], "3600s")

    def test_adapt_config_handles_missing_wait_for(self) -> None:
        """Verifies that steps without explicit waitFor are handled correctly."""
        # Mock trigger where steps don't have explicit waitFor (they run sequentially)
        mock_trigger = {
            "build": {
                "steps": [
                    {"id": "clone", "name": "git"},
                    {"id": "build", "name": "skaffold"},
                ]
            }
        }

        adapted = adapt_config(mock_trigger)
        self.assertEqual(len(adapted["steps"]), 1)
        self.assertEqual(adapted["steps"][0]["id"], "build")
        self.assertNotIn("waitFor", adapted["steps"][0])


if __name__ == "__main__":
    unittest.main()
