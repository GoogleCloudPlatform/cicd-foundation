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

package linkchecker

import (
	"os"
	"path/filepath"
	"testing"
)

func TestIsRelativeLink(t *testing.T) {
	tests := []struct {
		link string
		want bool
	}{
		{"", false},
		{"http://example.com", false},
		{"https://example.com/foo", false},
		{"mailto:test@example.com", false},
		{"tel:123456", false},
		{"#anchor", false},
		{"chrome-extension://foo", false},
		{"file:///path/to/file", false},
		{"./foo.md", true},
		{"../bar.md", true},
		{"foo/bar.md", true},
		{"/foo/bar.md", true},
		{"foo.md#section", true},
		{"foo.md?param=value", true},
	}

	for _, tt := range tests {
		t.Run(tt.link, func(t *testing.T) {
			t.Helper()
			if got := IsRelativeLink(tt.link); got != tt.want {
				t.Errorf("IsRelativeLink(%q) = %v, want %v", tt.link, got, tt.want)
			}
		})
	}
}

func TestCleanLink(t *testing.T) {
	tests := []struct {
		link string
		want string
	}{
		{"foo.md", "foo.md"},
		{"foo.md#section", "foo.md"},
		{"foo.md?param=value", "foo.md"},
		{"foo.md?param=value#section", "foo.md"},
		{"  foo.md  ", "foo.md"},
	}

	for _, tt := range tests {
		t.Run(tt.link, func(t *testing.T) {
			t.Helper()
			if got := CleanLink(tt.link); got != tt.want {
				t.Errorf("CleanLink(%q) = %q, want %q", tt.link, got, tt.want)
			}
		})
	}
}

func TestCheckFile(t *testing.T) {
	// Create a temp directory for tests
	tmpDir, err := os.MkdirTemp("", "linkchecker_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create some dummy target files
	validFile := filepath.Join(tmpDir, "valid.md")
	if err := os.WriteFile(validFile, []byte("valid"), 0644); err != nil {
		t.Fatalf("Failed to create valid.md: %v", err)
	}

	// Create a markdown file to check
	checkContent := `
# Test Markdown

This is a [valid link](./valid.md).
This is a [broken link](./broken.md).
This is an [external link](https://google.com).

Here is a link in a code block that should be ignored:
` + "`[ignored link](./broken.md)`" + `

Here is a multi-line code block to ignore:
` + "```markdown" + `
[ignored block link](./broken.md)
` + "```" + `

Here is an HTML comment that should be ignored:
<!-- [ignored comment link](./broken.md) -->

This is a [valid root relative link](/valid.md) if repo root is set to tmpDir.
This is a [broken root relative link](/broken.md).
`

	testFile := filepath.Join(tmpDir, "test.md")
	if err := os.WriteFile(testFile, []byte(checkContent), 0644); err != nil {
		t.Fatalf("Failed to create test.md: %v", err)
	}

	// Run CheckFile
	broken, err := CheckFile(testFile, tmpDir)
	if err != nil {
		t.Fatalf("CheckFile failed: %v", err)
	}

	// We expect 2 broken links:
	// 1. [broken link](./broken.md) (line 5)
	// 2. [broken root relative link](/broken.md) (line 20)
	expected := []struct {
		link    string
		lineNum int
	}{
		{"./broken.md", 5},
		{"/broken.md", 20},
	}

	if len(broken) != len(expected) {
		t.Fatalf("Expected %d broken links, got %d: %v", len(expected), len(broken), broken)
	}

	for i, ext := range expected {
		got := broken[i]
		if got.Link != ext.link {
			t.Errorf("Link[%d] = %q, want %q", i, got.Link, ext.link)
		}
		if got.LineNum != ext.lineNum {
			t.Errorf("LineNum[%d] (link %s) = %d, want %d", i, ext.link, got.LineNum, ext.lineNum)
		}
	}
}

func TestCheckFile_Error(t *testing.T) {
	_, err := CheckFile("non_existent_file.md", "")
	if err == nil {
		t.Error("Expected error when checking non-existent file, got nil")
	}
}
