// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// TestMainSmokeTest runs the main function in a separate process to verify it starts and displays usage correctly.
func TestMainSmokeTest(t *testing.T) {
	if os.Getenv("BE_CRASHER") == "1" {
		os.Args = []string{"license_enforcer"}
		main()
		return
	}

	cmd := exec.Command(os.Args[0], "-test.run=TestMainSmokeTest")
	cmd.Env = append(os.Environ(), "BE_CRASHER=1")
	err := cmd.Run()
	if err != nil {
		// main() with no args exits with 0 (displays usage), which is expected.
		// If it exited with non-zero, cmd.Run() would return an error.
		t.Fatalf("main() exited with error: %v", err)
	}
}

// TestMainWithArgs verify that main can handle file arguments.
func TestMainWithArgs(t *testing.T) {
	// Create a temp file to process
	tmpFile, err := os.CreateTemp("", "test_enforcer_*.ts")
	if err != nil {
		t.Fatalf("failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	content := "/**\n * Copyright 2026 Google LLC\n */\n\nfunction test() {}"
	if _, err := tmpFile.WriteString(content); err != nil {
		t.Fatalf("failed to write to temp file: %v", err)
	}
	tmpFile.Close()

	if os.Getenv("BE_CRASHER_ARGS") == "1" {
		os.Args = []string{"license_enforcer", os.Getenv("TEST_FILE")}
		main()
		return
	}

	cmd := exec.Command(os.Args[0], "-test.run=TestMainWithArgs")
	cmd.Env = append(os.Environ(), "BE_CRASHER_ARGS=1", "TEST_FILE="+tmpFile.Name())

	// We expect exit code 1 because the file will be modified (license added).
	err = cmd.Run()
	if err == nil {
		t.Fatal("expected main() to exit with error (code 1) due to file modification, but it exited with 0")
	}

	if exitError, ok := err.(*exec.ExitError); ok {
		if exitError.ExitCode() != 1 {
			t.Fatalf("expected exit code 1, got %d", exitError.ExitCode())
		}
	} else {
		t.Fatalf("cmd.Run() failed with non-exit error: %v", err)
	}
}

func TestRun(t *testing.T) {
	// Setup a temporary directory structure
	tmpDir, err := os.MkdirTemp("", "test_run_*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create some files
	files := []struct {
		path    string
		content string
	}{
		{"file1.ts", "function f1() {}"},
		{"subdir/file2.py", "print('f2')"},
		{"exclude_me/file3.js", "console.log('f3')"},
		{"filter_me.txt", "not a code file"},
	}

	for _, f := range files {
		fullPath := filepath.Join(tmpDir, f.path)
		if err := os.MkdirAll(filepath.Dir(fullPath), 0755); err != nil {
			t.Fatalf("failed to create dir %s: %v", filepath.Dir(fullPath), err)
		}
		if err := os.WriteFile(fullPath, []byte(f.content), 0644); err != nil {
			t.Fatalf("failed to write file %s: %v", fullPath, err)
		}
	}

	t.Run("basic_run", func(t *testing.T) {
		err := run("Google LLC", "Apache-2.0", "exclude_me", `\.(ts|py|js)$`, []string{tmpDir})
		if err == nil || err.Error() != "files modified" {
			t.Errorf("expected 'files modified' error, got %v", err)
		}

		// Verify file1.ts was modified
		data, _ := os.ReadFile(filepath.Join(tmpDir, "file1.ts"))
		if !strings.Contains(string(data), "Copyright") {
			t.Error("file1.ts was not modified")
		}

		// Verify exclude_me/file3.js was NOT modified
		data, _ = os.ReadFile(filepath.Join(tmpDir, "exclude_me/file3.js"))
		if strings.Contains(string(data), "Copyright") {
			t.Error("exclude_me/file3.js was modified but should have been excluded")
		}

		// Verify filter_me.txt was NOT modified
		data, _ = os.ReadFile(filepath.Join(tmpDir, "filter_me.txt"))
		if strings.Contains(string(data), "Copyright") {
			t.Error("filter_me.txt was modified but should have been filtered")
		}
	})

	t.Run("no_args", func(t *testing.T) {
		err := run("Google LLC", "Apache-2.0", "", "", nil)
		if err != nil {
			t.Errorf("expected nil error for no args, got %v", err)
		}
	})
}
