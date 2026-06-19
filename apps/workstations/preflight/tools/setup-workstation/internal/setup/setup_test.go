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
	"bytes"
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/charmbracelet/huh"
	"gopkg.in/yaml.v3"
)

func TestLoadConfig(t *testing.T) {
	tmpDir := t.TempDir()

	tests := []struct {
		name    string
		content string
		wantErr bool
	}{
		{
			name: "Valid cfg",
			content: `
inputs:
  - id: gcp_project
    prompt: "GCP Project ID"
    default_env: "AGY_GCP_PROJECT"
    required: true
`,
			wantErr: false,
		},
		{
			name:    "Invalid YAML",
			content: `inputs: [`,
			wantErr: true,
		},
		{
			name:    "Missing file",
			content: "",
			wantErr: true,
		},
		{
			name: "Unknown fields",
			content: `
inputs:
  - id: gcp_project
    prompt: "GCP Project ID"
    required: true
unknown_key: "invalid"
`,
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			path := filepath.Join(tmpDir, "cfg_"+tt.name+".yaml")
			if tt.name != "Missing file" {
				if err := os.WriteFile(path, []byte(tt.content), 0644); err != nil {
					t.Fatalf("Failed to write test file: %v", err)
				}
			}

			cfg, err := loadConfig(path)
			if (err != nil) != tt.wantErr {
				t.Errorf("loadConfig() error = %v, wantErr %v", err, tt.wantErr)
			}
			if !tt.wantErr && cfg == nil {
				t.Errorf("expected cfg to not be nil")
			}
		})
	}
}

func TestResolveDefaults(t *testing.T) {
	cfg := &Config{
		Inputs: []Input{
			{ID: "project", DefaultEnv: "PROJECT_ID"},
			{ID: "region", DefaultEnv: "REGION"},
		},
	}

	tests := []struct {
		name    string
		environ []string
		want    map[string]interface{}
	}{
		{
			name:    "Both vars present",
			environ: []string{"PROJECT_ID=my-project", "REGION=us-central1"},
			want:    map[string]interface{}{"project": "my-project", "region": "us-central1"},
		},
		{
			name:    "One var missing",
			environ: []string{"PROJECT_ID=my-project"},
			want:    map[string]interface{}{"project": "my-project"},
		},
		{
			name:    "Empty values ignored",
			environ: []string{"PROJECT_ID=my-project", "REGION="},
			want:    map[string]interface{}{"project": "my-project"},
		},
		{
			name:    "No vars present",
			environ: []string{},
			want:    map[string]interface{}{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			envFunc := func() []string {
				return tt.environ
			}

			got := resolveDefaults(cfg, envFunc)
			if len(got) != len(tt.want) {
				t.Errorf("resolveDefaults() got %v entries, want %v", len(got), len(tt.want))
			}
			for k, v := range tt.want {
				if got[k] != v {
					t.Errorf("resolveDefaults()[%q] = %v, want %v", k, got[k], v)
				}
			}
		})
	}
}

func TestBuildAndRunForm(t *testing.T) {
	mockRunner := func(form *huh.Form) error {
		return nil
	}

	cfg := &Config{
		Inputs: []Input{
			{ID: "project", Prompt: "GCP Project", Required: true},
			{ID: "region", Prompt: "Region", Default: "us-central1", Required: false},
			{ID: "model", Prompt: "Model", Validation: struct {
				Type    string   `yaml:"type"`
				Options []string `yaml:"options"`
			}{Type: "enum", Options: []string{"a", "b"}}},
		},
	}

	answers := make(map[string]interface{})
	var missingOptionals []string

	err := buildAndRunForm(cfg, answers, nil, mockRunner, &missingOptionals)
	if err != nil {
		t.Fatalf("buildAndRunForm() failed: %v", err)
	}

	// Because we mocked runForm to just return nil, it won't actually update answers with user input,
	// but it WILL use defaults!
	if answers["region"] != "us-central1" {
		t.Errorf("Expected region to use default 'us-central1', got %v", answers["region"])
	}
}

func TestBuildAndRunForm_Error(t *testing.T) {
	mockRunner := func(form *huh.Form) error {
		return errors.New("user cancelled")
	}

	cfg := &Config{
		Inputs: []Input{{ID: "project", Prompt: "GCP Project"}},
	}
	answers := make(map[string]interface{})
	var missingOptionals []string

	err := buildAndRunForm(cfg, answers, nil, mockRunner, &missingOptionals)
	if err == nil {
		t.Fatalf("Expected buildAndRunForm() to fail when form.Run() returns an error")
	}
}

func TestBuildAndRunForm_Prefill(t *testing.T) {
	mockRunner := func(form *huh.Form) error {
		return nil
	}

	cfg := &Config{
		Inputs: []Input{
			{ID: "project", Prompt: "GCP Project", Default: "default-project"},
			{ID: "region", Prompt: "Region", Default: "us-central1"},
		},
	}

	answers := make(map[string]interface{})
	previousAnswers := map[string]string{
		"project": "my-previous-project",
	}
	var missingOptionals []string

	err := buildAndRunForm(cfg, answers, previousAnswers, mockRunner, &missingOptionals)
	if err != nil {
		t.Fatalf("buildAndRunForm() failed: %v", err)
	}

	if answers["project"] != "my-previous-project" {
		t.Errorf("Expected project to prefill with 'my-previous-project', got %v", answers["project"])
	}
	if answers["region"] != "us-central1" {
		t.Errorf("Expected region to fall back to default 'us-central1', got %v", answers["region"])
	}
}

func TestBuildAndRunForm_ExplicitClear(t *testing.T) {
	mockRunner := func(form *huh.Form) error {
		return nil
	}

	cfg := &Config{
		Inputs: []Input{
			{ID: "project", Prompt: "GCP Project", Default: "default-project"},
		},
	}

	answers := make(map[string]interface{})
	previousAnswers := map[string]string{
		"project": "", // User explicitly cleared it in previous run
	}
	var missingOptionals []string

	err := buildAndRunForm(cfg, answers, previousAnswers, mockRunner, &missingOptionals)
	if err != nil {
		t.Fatalf("buildAndRunForm() failed: %v", err)
	}

	if answers["project"] != "" {
		t.Errorf("Expected project to remain explicitly empty, got %v", answers["project"])
	}
}

func TestWriteChezmoiData(t *testing.T) {
	tmpHome := t.TempDir()

	answers := map[string]interface{}{
		"project": "my-project",
	}
	missingOptionals := []string{"mcp_url"}
	var warnBuf bytes.Buffer
	err := writeChezmoiData(tmpHome, answers, missingOptionals, &warnBuf)
	if err != nil {
		t.Fatalf("writeChezmoiData() unexpected error: %v", err)
	}

	warnStr := warnBuf.String()
	if !strings.Contains(warnStr, "Warning: Optional input 'mcp_url' was omitted") {
		t.Errorf("Expected warnings to contain 'Warning: Optional input 'mcp_url' was omitted', got: %q", warnStr)
	}

	// Verify chezmoi.yaml
	chezmoiDataPath := filepath.Join(tmpHome, ".config", "chezmoi", chezmoiConfigFileName)
	data, err := os.ReadFile(chezmoiDataPath)
	if err != nil {
		t.Fatalf("Failed to read generated %s: %v", chezmoiConfigFileName, err)
	}

	// Verify file permissions (0600)
	info, err := os.Stat(chezmoiDataPath)
	if err != nil {
		t.Fatalf("Failed to stat generated %s: %v", chezmoiConfigFileName, err)
	}
	if info.Mode().Perm() != 0600 {
		t.Errorf("Expected 0600 permissions on %s, got %v", chezmoiDataPath, info.Mode().Perm())
	}

	var parsed map[string]interface{}
	if err := yaml.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("Generated %s is invalid: %v", chezmoiConfigFileName, err)
	}

	dataBlock, ok := parsed["data"].(map[string]interface{})
	if !ok {
		t.Fatalf("Generated %s missing 'data' block", chezmoiConfigFileName)
	}

	if dataBlock["project"] != "my-project" {
		t.Errorf("Expected project 'my-project', got '%v'", dataBlock["project"])
	}
}

func TestMarkDone(t *testing.T) {
	t.Run("Standard fallback", func(t *testing.T) {
		tmpHome := t.TempDir()
		t.Setenv("XDG_STATE_HOME", "") // Ensure cleared
		if err := markDone(tmpHome); err != nil {
			t.Fatalf("markDone() unexpected error: %v", err)
		}

		doneFile := filepath.Join(tmpHome, ".local", "state", doneFileName)
		if _, err := os.Stat(doneFile); os.IsNotExist(err) {
			t.Errorf("Expected done flag file to be created at default path")
		}
	})

	t.Run("XDG_STATE_HOME override", func(t *testing.T) {
		tmpHome := t.TempDir()
		customStateDir := filepath.Join(tmpHome, "custom", "state")
		t.Setenv("XDG_STATE_HOME", customStateDir)

		if err := markDone(tmpHome); err != nil {
			t.Fatalf("markDone() unexpected error: %v", err)
		}

		doneFile := filepath.Join(customStateDir, doneFileName)
		if _, err := os.Stat(doneFile); os.IsNotExist(err) {
			t.Errorf("Expected done flag file to be created at custom XDG path")
		}
	})
}

func TestLoadPreviousAnswers(t *testing.T) {
	tmpHome := t.TempDir()

	// 1. Test missing file -> should return (nil, nil)
	answers, err := loadPreviousAnswers(tmpHome)
	if err != nil {
		t.Fatalf("Expected no error when file is missing, got %v", err)
	}
	if answers != nil {
		t.Errorf("Expected nil answers when file is missing, got %v", answers)
	}

	// 2. Test valid chezmoi.yaml parsing
	chezmoiDir := filepath.Join(tmpHome, ".config", "chezmoi")
	if err := os.MkdirAll(chezmoiDir, 0755); err != nil {
		t.Fatalf("Failed to create config dir: %v", err)
	}
	yamlContent := `
data:
  gcp_project: parsed-project
  mcp_server_url: parsed-url
`
	if err := os.WriteFile(filepath.Join(chezmoiDir, chezmoiConfigFileName), []byte(yamlContent), 0644); err != nil {
		t.Fatalf("Failed to write test %s: %v", chezmoiConfigFileName, err)
	}

	answers, err = loadPreviousAnswers(tmpHome)
	if err != nil {
		t.Fatalf("Unexpected error loading previous answers: %v", err)
	}
	if answers == nil {
		t.Fatalf("Expected non-nil answers")
	}
	if answers["gcp_project"] != "parsed-project" {
		t.Errorf("Expected gcp_project 'parsed-project', got '%v'", answers["gcp_project"])
	}
	if answers["mcp_server_url"] != "parsed-url" {
		t.Errorf("Expected mcp_server_url 'parsed-url', got '%v'", answers["mcp_server_url"])
	}

	// 3. Test invalid YAML parsing -> should return error
	invalidContent := `
data:
  gcp_project: {unclosed bracket
`
	if err := os.WriteFile(filepath.Join(chezmoiDir, chezmoiConfigFileName), []byte(invalidContent), 0644); err != nil {
		t.Fatalf("Failed to write test %s: %v", chezmoiConfigFileName, err)
	}

	_, err = loadPreviousAnswers(tmpHome)
	if err == nil {
		t.Errorf("Expected error when parsing invalid YAML, got nil")
	}
}

type MockShell struct{}

func (m *MockShell) Run(ctx context.Context, name string, args ...string) error {
	return nil
}

func (m *MockShell) Output(ctx context.Context, name string, args ...string) ([]byte, error) {
	return []byte("/home/user/.gemini/antigravity-cli/mcp_config.json\n"), nil
}

func TestRun_EndToEnd(t *testing.T) {
	tmpHome := t.TempDir()

	// Create a dummy cfg
	configContent := `
inputs:
  - id: gcp_project
    prompt: "GCP Project ID"
    default_env: "AGY_GCP_PROJECT"
    required: true
`
	configPath := filepath.Join(tmpHome, "setup-workstation.yaml")
	if err := os.WriteFile(configPath, []byte(configContent), 0644); err != nil {
		t.Fatalf("Failed to write cfg: %v", err)
	}

	t.Setenv("AGY_GCP_PROJECT", "test-project") // Satisfies the required input, skipping the prompt

	dummySource := filepath.Join(tmpHome, "dummy_source.d")
	if err := os.MkdirAll(dummySource, 0755); err != nil {
		t.Fatalf("Failed to MkdirAll: %v", err)
	}
	if err := os.WriteFile(filepath.Join(dummySource, "dummy.txt"), []byte("data"), 0644); err != nil {
		t.Fatalf("Failed to write dummy template file: %v", err)
	}

	var stdoutBuf, stderrBuf bytes.Buffer
	opts := Options{
		HomeDir:    tmpHome,
		ConfigPath: configPath,
		SourceDir:  dummySource,
		Stdout:     &stdoutBuf,
		Stderr:     &stderrBuf,
	}

	err := Run(context.Background(), opts, &MockShell{})

	out := stdoutBuf.String()

	if err != nil {
		t.Fatalf("run() unexpected error: %v", err)
	}

	// Verify output prints
	if !strings.Contains(out, "Applying configuration...") {
		t.Errorf("Expected output to contain 'Applying configuration...', got: %q", out)
	}
	if !strings.Contains(out, "Generated Files:") {
		t.Errorf("Expected output to contain 'Generated Files:', got: %q", out)
	}
	if !strings.Contains(out, "  - /home/user/.gemini/antigravity-cli/mcp_config.json") {
		t.Errorf("Expected output to contain generated file path, got: %q", out)
	}
	if !strings.Contains(out, "Workspace setup complete!") {
		t.Errorf("Expected output to contain 'Workspace setup complete!', got: %q", out)
	}

	// Verify the flag file was created
	doneFile := filepath.Join(tmpHome, ".local", "state", doneFileName)
	if _, err := os.Stat(doneFile); os.IsNotExist(err) {
		t.Errorf("Expected done flag file to be created")
	}
}

func TestRun_NoConfig(t *testing.T) {
	opts := Options{
		HomeDir:    t.TempDir(),
		ConfigPath: "/does/not/exist.yaml",
		SourceDir:  t.TempDir(),
	}

	err := Run(context.Background(), opts, nil)
	if err == nil {
		t.Fatalf("run() expected an error when cfg is missing")
	}
}

func TestPrepareSourceDir(t *testing.T) {
	srcDir := t.TempDir()
	if err := os.MkdirAll(filepath.Join(srcDir, ".gemini", "foo"), 0755); err != nil {
		t.Fatalf("Failed to create dir: %v", err)
	}
	if err := os.WriteFile(filepath.Join(srcDir, ".gemini", "foo", ".config.json"), []byte("{}"), 0644); err != nil {
		t.Fatalf("Failed to write test file: %v", err)
	}
	if err := os.WriteFile(filepath.Join(srcDir, ".gemini", "foo", "private_script.sh"), []byte("#!/bin/sh"), 0755); err != nil {
		t.Fatalf("Failed to write test file: %v", err)
	}

	permissions := []PermissionRule{
		{Path: ".gemini/foo/.config.json", Mode: "0600"},
		{Path: ".gemini/foo", Mode: "0755"},
		{Path: ".gemini/foo/private_script.sh", Mode: "0700"},
	}

	tmpDir, err := prepareSourceDir(srcDir, permissions)
	if err != nil {
		t.Fatalf("prepareSourceDir failed: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	expectedPath := filepath.Join(tmpDir, "dot_gemini", "executable_foo", "private_dot_config.json.tmpl")
	if _, err := os.Stat(expectedPath); os.IsNotExist(err) {
		t.Fatalf("Expected translated file not found: %s", expectedPath)
	}

	expectedScriptPath := filepath.Join(tmpDir, "dot_gemini", "executable_foo", "private_executable_private_script.sh.tmpl")
	if _, err := os.Stat(expectedScriptPath); os.IsNotExist(err) {
		t.Fatalf("Expected translated script not found: %s", expectedScriptPath)
	}
}

func TestTranslatePath(t *testing.T) {
	permMap := map[string]string{
		".gemini/foo/.config.json": "0600",
		".gemini/foo":              "0755",
		".gemini/foo/script.sh":    "0700",
		"readonly_file.txt":        "0444",
		"executable_only.sh":       "0500",
	}

	tests := []struct {
		name     string
		relPath  string
		isDir    bool
		expected string
	}{
		{
			name:     "Hidden directory conversion",
			relPath:  ".gemini/foo",
			isDir:    true,
			expected: "dot_gemini/executable_foo",
		},
		{
			name:     "Private file conversion (0600)",
			relPath:  ".gemini/foo/.config.json",
			isDir:    false,
			expected: "dot_gemini/executable_foo/private_dot_config.json.tmpl",
		},
		{
			name:     "Private executable owner file conversion (0700)",
			relPath:  ".gemini/foo/script.sh",
			isDir:    false,
			expected: "dot_gemini/executable_foo/private_executable_script.sh.tmpl",
		},
		{
			name:     "Read-only file conversion (0444)",
			relPath:  "readonly_file.txt",
			isDir:    false,
			expected: "readonly_readonly_file.txt.tmpl",
		},
		{
			name:     "Private executable owner read-only file conversion (0500)",
			relPath:  "executable_only.sh",
			isDir:    false,
			expected: "private_executable_executable_only.sh.tmpl",
		},
		{
			name:     "Static file template suffix append",
			relPath:  "some/plain_file.txt",
			isDir:    false,
			expected: "some/plain_file.txt.tmpl",
		},
		{
			name:     "Tmpl suffix is not duplicated",
			relPath:  "some/plain_file.txt.tmpl",
			isDir:    false,
			expected: "some/plain_file.txt.tmpl",
		},
		{
			name:     "Directories do not get template suffix",
			relPath:  "some/directory",
			isDir:    true,
			expected: "some/directory",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := translatePath(tt.relPath, tt.isDir, permMap)
			if result != tt.expected {
				t.Errorf("translatePath(%q, %v) = %q; expected %q", tt.relPath, tt.isDir, result, tt.expected)
			}
		})
	}
}

func TestIsDone(t *testing.T) {
	t.Run("Standard fallback", func(t *testing.T) {
		tmpHome := t.TempDir()
		t.Setenv("XDG_STATE_HOME", "")

		if IsDone(tmpHome) {
			t.Fatalf("IsDone() expected to return false when state file does not exist")
		}

		if err := markDone(tmpHome); err != nil {
			t.Fatalf("markDone() unexpected error: %v", err)
		}

		if !IsDone(tmpHome) {
			t.Fatalf("IsDone() expected to return true after state file is created")
		}
	})

	t.Run("XDG_STATE_HOME override", func(t *testing.T) {
		tmpHome := t.TempDir()
		customStateDir := filepath.Join(tmpHome, "custom", "state")
		t.Setenv("XDG_STATE_HOME", customStateDir)

		if IsDone(tmpHome) {
			t.Fatalf("IsDone() expected to return false when state file does not exist")
		}

		if err := markDone(tmpHome); err != nil {
			t.Fatalf("markDone() unexpected error: %v", err)
		}

		if !IsDone(tmpHome) {
			t.Fatalf("IsDone() expected to return true after state file is created")
		}
	})
}

func TestRun_ForceReset(t *testing.T) {
	tmpHome := t.TempDir()

	// 1. Write mock previous answers in chezmoi.yaml
	chezmoiDir := filepath.Join(tmpHome, ".config", "chezmoi")
	if err := os.MkdirAll(chezmoiDir, 0755); err != nil {
		t.Fatalf("Failed to create config dir: %v", err)
	}
	// Previous answers has "my-project"
	yamlContent := "data:\n  gcp_project: my-project\n"
	if err := os.WriteFile(filepath.Join(chezmoiDir, chezmoiConfigFileName), []byte(yamlContent), 0644); err != nil {
		t.Fatalf("Failed to write test chezmoi.yaml: %v", err)
	}

	// 2. Setup config with a schema default "default-project"
	configContent := `
inputs:
  - id: gcp_project
    prompt: "GCP Project"
    default: default-project
`
	configPath := filepath.Join(tmpHome, "config.yaml")
	if err := os.WriteFile(configPath, []byte(configContent), 0644); err != nil {
		t.Fatalf("Failed to write config: %v", err)
	}

	opts := Options{
		HomeDir:    tmpHome,
		ConfigPath: configPath,
		SourceDir:  t.TempDir(),
		ForceReset: true,
		FormRunner: func(form *huh.Form) error { return nil },
	}

	_, answers, _, err := collectAnswers(opts)
	if err != nil {
		t.Fatalf("collectAnswers failed: %v", err)
	}

	// 3. Verify that the answer resolved to the schema default instead of the previous chezmoi.yaml value
	if answers["gcp_project"] != "default-project" {
		t.Errorf("Expected gcp_project to fall back to schema default 'default-project', got %q", answers["gcp_project"])
	}
}

func TestRun_MarkDoneError(t *testing.T) {
	tmpHome := t.TempDir()

	// To cause markDone to fail, we create a regular file at where it expects state directory .local/state
	stateDirParent := filepath.Join(tmpHome, ".local")
	if err := os.MkdirAll(stateDirParent, 0755); err != nil {
		t.Fatalf("Failed to create .local dir: %v", err)
	}
	stateFilePath := filepath.Join(stateDirParent, "state")
	if err := os.WriteFile(stateFilePath, []byte("i am a file, not a directory"), 0644); err != nil {
		t.Fatalf("Failed to create blocking file: %v", err)
	}

	configContent := `
inputs:
  - id: gcp_project
    prompt: "GCP Project"
    required: true
`
	configPath := filepath.Join(tmpHome, "config.yaml")
	if err := os.WriteFile(configPath, []byte(configContent), 0644); err != nil {
		t.Fatalf("Failed to write config: %v", err)
	}

	dummySource := filepath.Join(tmpHome, "dummy_source.d")
	if err := os.MkdirAll(dummySource, 0755); err != nil {
		t.Fatalf("Failed to MkdirAll: %v", err)
	}
	if err := os.WriteFile(filepath.Join(dummySource, "dummy.txt"), []byte("data"), 0644); err != nil {
		t.Fatalf("Failed to write dummy template file: %v", err)
	}

	var stdoutBuf, stderrBuf bytes.Buffer
	opts := Options{
		HomeDir:    tmpHome,
		ConfigPath: configPath,
		SourceDir:  dummySource,
		Stdout:     &stdoutBuf,
		Stderr:     &stderrBuf,
		FormRunner: func(form *huh.Form) error { return nil },
	}

	// This Run will succeed through applying state, but fail when attempting to write the done flag file
	err := Run(context.Background(), opts, &MockShell{})
	if err == nil {
		t.Fatalf("Run expected to fail due to markDone failure, got nil")
	}

	if !strings.Contains(err.Error(), "failed to mark setup as done:") {
		t.Errorf("Expected error to contain markDone failure message, got: %q", err.Error())
	}
}

func TestCheckRunnable(t *testing.T) {
	tmpHome := t.TempDir()

	// 1. Config missing -> error
	opts := Options{
		HomeDir:    tmpHome,
		ConfigPath: filepath.Join(tmpHome, "nonexistent-config.yaml"),
		SourceDir:  filepath.Join(tmpHome, "nonexistent-source"),
	}
	err := CheckRunnable(opts)
	if err == nil || !strings.Contains(err.Error(), "config file does not exist") {
		t.Errorf("Expected config missing error, got: %v", err)
	}

	// Create valid config
	configPath := filepath.Join(tmpHome, "config.yaml")
	if err := os.WriteFile(configPath, []byte("inputs: []"), 0644); err != nil {
		t.Fatalf("Failed to write config: %v", err)
	}
	opts.ConfigPath = configPath

	// 2. Source dir missing -> error
	err = CheckRunnable(opts)
	if err == nil || !strings.Contains(err.Error(), "template source directory does not exist") {
		t.Errorf("Expected source dir missing error, got: %v", err)
	}

	// Create empty source dir
	sourceDir := filepath.Join(tmpHome, "source.d")
	if err := os.MkdirAll(sourceDir, 0755); err != nil {
		t.Fatalf("Failed to MkdirAll: %v", err)
	}
	opts.SourceDir = sourceDir

	// 3. Source dir empty -> error
	err = CheckRunnable(opts)
	if err == nil || !strings.Contains(err.Error(), "template source directory is empty") {
		t.Errorf("Expected source dir empty error, got: %v", err)
	}

	// Write a file to source dir
	if err := os.WriteFile(filepath.Join(sourceDir, "test.txt"), []byte("data"), 0644); err != nil {
		t.Fatalf("Failed to write template file: %v", err)
	}

	// 4. All exists -> success (nil)
	err = CheckRunnable(opts)
	if err != nil {
		t.Errorf("Expected CheckRunnable to succeed, got error: %v", err)
	}
}
