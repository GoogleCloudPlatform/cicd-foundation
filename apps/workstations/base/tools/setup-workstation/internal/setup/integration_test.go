/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package setup

import (
	"context"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

const (
	testGCPProject   = "integration-test-project"
	testMCPServerURL = "https://mcp.integration.com/sse"
	testMCPAuthToken = "integration-secret-token"
)

func TestEndToEnd_Integration(t *testing.T) {
	// Skip if the chezmoi binary is not available on the host system
	if _, err := exec.LookPath("chezmoi"); err != nil {
		t.Skip("skipping integration test: chezmoi binary not found in PATH")
	}

	// Setup isolated HOME directory
	homeDir := t.TempDir()
	t.Setenv("HOME", homeDir)

	// Setup environment variables to bypass the interactive TUI
	// Point to our isolated testdata for the integration test
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get working directory: %v", err)
	}
	configPath := filepath.Join(cwd, "testdata", "setup-workstation.yaml")
	sourcePath := filepath.Join(cwd, "testdata", "templates")
	t.Setenv("AGY_GCP_PROJECT", testGCPProject)
	t.Setenv("AGY_MCP_SERVER_URL", testMCPServerURL)
	t.Setenv("AGY_MCP_AUTH_TOKEN", testMCPAuthToken)

	opts := Options{
		HomeDir:    homeDir,
		ConfigPath: configPath,
		SourceDir:  sourcePath,
	}

	// Run the full execution (we can invoke Run() directly to avoid os.Exit)
	err = Run(context.Background(), opts, nil)
	if err != nil {
		t.Fatalf("run() failed: %v", err)
	}

	// Validate Expected Outcomes

	// Validate settings.json
	settingsPath := filepath.Join(homeDir, ".gemini", "antigravity-cli", "settings.json")
	settingsData, err := os.ReadFile(settingsPath)
	if err != nil {
		t.Fatalf("failed to read generated settings.json: %v", err)
	}

	var settings map[string]interface{}
	if err := json.Unmarshal(settingsData, &settings); err != nil {
		t.Fatalf("generated settings.json is not valid JSON: %v", err)
	}

	// Check GCP project injection
	gcp := settings["gcp"].(map[string]interface{})
	if gcp["project"] != testGCPProject {
		t.Errorf("expected gcp.project %q, got '%v'", testGCPProject, gcp["project"])
	}

	// Validate mcp_config.json
	mcpPath := filepath.Join(homeDir, ".gemini", "antigravity-cli", "mcp_config.json")
	mcpData, err := os.ReadFile(mcpPath)
	if err != nil {
		t.Fatalf("failed to read generated mcp_config.json: %v", err)
	}

	var mcp map[string]interface{}
	if err := json.Unmarshal(mcpData, &mcp); err != nil {
		t.Fatalf("generated mcp_config.json is not valid JSON: %v", err)
	}

	// Check MCP server injection
	servers := mcp["mcpServers"].(map[string]interface{})
	remote := servers["remote-indexer"].(map[string]interface{})
	if remote["serverUrl"] != testMCPServerURL {
		t.Errorf("expected serverUrl %q, got '%v'", testMCPServerURL, remote["serverUrl"])
	}

	env := remote["env"].(map[string]interface{})
	if env["AUTH_TOKEN"] != testMCPAuthToken {
		t.Errorf("expected AUTH_TOKEN %q, got '%v'", testMCPAuthToken, env["AUTH_TOKEN"])
	}
}
