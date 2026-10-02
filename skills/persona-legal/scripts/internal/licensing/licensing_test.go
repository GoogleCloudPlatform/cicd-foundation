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

package licensing

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestProcessFileContent(t *testing.T) {
	tests := []struct {
		name           string
		content        string
		ext            string
		currentYear    int
		holder         string
		targetLicense  string
		format         string
		wantModified   bool
		wantAdded      bool
		wantUpdated    bool
		wantDifferentH string
		contains       []string
	}{
		{
			name:          "adds_license_to_empty_file",
			content:       "",
			ext:           "py",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantAdded:     true,
			contains:      []string{"Copyright 2026 Google LLC", "Licensed under the Apache License, Version 2.0"},
		},
		{
			name: "updates_past_year",
			content: strings.TrimPrefix(`
# Copyright 2024-2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");`, "\n"),
			ext:           "py",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantUpdated:   true,
			contains:      []string{"Copyright 2024-2026 Google LLC"},
		},
		{
			name: "updates_past_year_range",
			content: strings.TrimPrefix(`
# Copyright 2022-2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");`, "\n"),
			ext:           "py",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantUpdated:   true,
			contains:      []string{"Copyright 2022-2026 Google LLC"},
		},
		{
			name: "removes_short_copyright_header_ts",
			content: strings.TrimPrefix(`
function hello() {}`, "\n"),
			ext:           "ts",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantAdded:     true,
			contains:      []string{"Copyright 2026 Google LLC", "Licensed under the Apache License, Version 2.0"},
		},
		{
			name:           "warns_on_different_holder",
			content:        "# Copyright 2024 Google Inc. All Rights Reserved.\n",
			ext:            "py",
			currentYear:    2026,
			holder:         "Google LLC",
			targetLicense:  "Apache-2.0",
			wantModified:   false,
			wantAdded:      false,
			wantDifferentH: "Google Inc. All Rights Reserved.",
		},
		{
			name: "ignores_current_year",
			content: strings.TrimPrefix(`
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
`, "\n"),
			ext:           "py",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  false,
		},
		{
			name: "preserves_old_year_on_new_license_addition",
			content: strings.TrimPrefix(`
# Copyright 2024-2026 Google LLC

print('hello')`, "\n"),
			ext:           "py",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantAdded:     true,
			wantUpdated:   true,
			contains:      []string{"Copyright 2024-2026 Google LLC"},
		},
		{
			name: "removes_short_copyright_header_html",
			content: strings.TrimPrefix(`
# Title`, "\n"),
			ext:           "md",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantAdded:     true,
			contains:      []string{"Copyright 2026 Google LLC", "Licensed under the Apache License, Version 2.0"},
		},
		{
			name: "shebang_preservation",
			content: strings.TrimPrefix(`
#!/usr/bin/env python3

print('hello')`, "\n"),
			ext:           "py",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantAdded:     true,
			contains:      []string{"#!/usr/bin/env python3", "Copyright 2026 Google LLC"},
		},
		{
			name: "xml_declaration_preservation",
			content: strings.TrimPrefix(`
<?xml version="1.0" encoding="UTF-8"?>
<root></root>`, "\n"),
			ext:           "xml",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantAdded:     true,
			contains:      []string{"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<!--\nCopyright 2026 Google LLC"},
		},
		{
			name: "php_tag_preservation",
			content: strings.TrimPrefix(`
<?php
echo "Hello";
?>`, "\n"),
			ext:           "php",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantAdded:     true,
			// Using Hash format for php just as an example since it's not strictly mapped in the extensions by default in the file? Wait, php is not in the list!
			// If php is not supported, this might fail. I'll add php to the CStyleExtensions.
		},
		{
			name: "html_doctype_preservation",
			content: strings.TrimPrefix(`
<!DOCTYPE html>
<html></html>`, "\n"),
			ext:           "html",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantAdded:     true,
			contains:      []string{"<!DOCTYPE html>\n\n<!--\nCopyright 2026 Google LLC"},
		},
		{
			name:          "supports_go_files",
			content:       "package main\n\nfunc main() {}",
			ext:           "go",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantAdded:     true,
			contains:      []string{"/**", " * Copyright 2026 Google LLC", " */", "package main"},
		},
		{
			name:          "supports_dockerfiles",
			content:       "FROM alpine\nRUN echo hi",
			ext:           "dockerfile",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantAdded:     true,
			contains:      []string{"# Copyright 2026 Google LLC", "FROM alpine"},
		},
		{
			name:          "supports_xml_files",
			content:       "<root></root>",
			ext:           "xml",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantAdded:     true,
			contains:      []string{"<!--", "Copyright 2026 Google LLC", "-->", "<root>"},
		},
		{
			name:          "never_removes_existing_header_if_unsupported",
			content:       "<!-- Copyright 2025-2026 Google LLC -->\nsome content",
			ext:           "unsupported",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  false,
		},
		{
			name: "frontmatter_preservation",
			content: strings.TrimPrefix(`
---
name: my-skill
---

# Content`, "\n"),
			ext:           "md",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  true,
			wantAdded:     true,
			contains:      []string{"---\nname: my-skill\n---", "Copyright 2026 Google LLC"},
		},
		{
			name: "metadata_license_skip_header",
			content: strings.TrimPrefix(`
---
name: my-skill
license: Apache-2.0
---

# Content
`, "\n"),
			ext:           "md",
			currentYear:   2026,
			holder:        "Google LLC",
			targetLicense: "Apache-2.0",
			wantModified:  false,
			wantAdded:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, res := ProcessFileContent(tt.content, tt.ext, tt.currentYear, tt.holder, tt.targetLicense, "full")
			if res.Modified != tt.wantModified {
				t.Errorf("ProcessFileContent() modified = %v, want %v", res.Modified, tt.wantModified)
			}
			if res.LicenseAdded != tt.wantAdded {
				t.Errorf("ProcessFileContent() added = %v, want %v", res.LicenseAdded, tt.wantAdded)
			}
			if res.YearUpdated != tt.wantUpdated {
				t.Errorf("ProcessFileContent() updated = %v, want %v", res.YearUpdated, tt.wantUpdated)
			}
			if tt.wantDifferentH != "" && res.DifferentHolder != tt.wantDifferentH {
				t.Errorf("ProcessFileContent() differentHolder = %q, want %q", res.DifferentHolder, tt.wantDifferentH)
			}
			for _, s := range tt.contains {
				if !strings.Contains(got, s) {
					t.Errorf("ProcessFileContent() result does not contain %q", s)
				}
			}

			// Special check for duplication in removes_short_copyright_header_ts
			if tt.name == "removes_short_copyright_header_ts" {
				count := strings.Count(got, "Copyright 2026 Google LLC")
				if count != 1 {
					t.Errorf("ProcessFileContent() count of copyright notice = %d, want 1", count)
				}
			}
		})
	}
}

func TestHeaderFormatter(t *testing.T) {
	f := HeaderFormatter{}
	text := "Line 1\nLine 2"

	tests := []struct {
		ext  string
		want string
	}{
		{"py", "# Line 1\n# Line 2\n\n"},
		{"ts", "/**\n * Line 1\n * Line 2\n */\n\n"},
		{"md", "<!--\nLine 1\nLine 2\n-->\n\n"},
		{"go", "/**\n * Line 1\n * Line 2\n */\n\n"},
		{"dockerfile", "# Line 1\n# Line 2\n\n"},
		{"xml", "<!--\nLine 1\nLine 2\n-->\n\n"},
		{"unknown", ""},
	}

	for _, tt := range tests {
		t.Run(tt.ext, func(t *testing.T) {
			got := f.Format(text, tt.ext)
			if got != tt.want {
				t.Errorf("Format(%q) = %q, want %q", tt.ext, got, tt.want)
			}
		})
	}
}

func TestEnforceFile(t *testing.T) {
	// Create a temp file to process
	tmpFile, err := os.CreateTemp("", "test_enforce_*.ts")
	if err != nil {
		t.Fatalf("failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	content := "function test() {}"
	if _, err := tmpFile.WriteString(content); err != nil {
		t.Fatalf("failed to write to temp file: %v", err)
	}
	tmpFile.Close()

	res, err := EnforceFile(tmpFile.Name(), 2026, "Google LLC", "Apache-2.0", "full")
	if err != nil {
		t.Fatalf("EnforceFile() error = %v", err)
	}

	if !res.Modified || !res.LicenseAdded {
		t.Errorf("EnforceFile() result = %+v, want modified and added", res)
	}

	// Verify file content
	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("failed to read temp file: %v", err)
	}
	if !strings.Contains(string(data), "Copyright 2026 Google LLC") {
		t.Error("EnforceFile() did not add the license header")
	}

	t.Run("skips_binary_files", func(t *testing.T) {
		binFile, err := os.CreateTemp("", "test_enforce_*.bin")
		if err != nil {
			t.Fatal(err)
		}
		defer os.Remove(binFile.Name())

		// Write null byte
		if _, err := binFile.Write([]byte{0x7f, 0x45, 0x4c, 0x46, 0x00}); err != nil {
			t.Fatal(err)
		}
		binFile.Close()

		res, err := EnforceFile(binFile.Name(), 2026, "Google LLC", "Apache-2.0", "full")
		if err != nil {
			t.Fatal(err)
		}
		if res.Modified {
			t.Error("EnforceFile() modified binary file")
		}
	})

	t.Run("resolves_template_extensions", func(t *testing.T) {
		tmpDir, err := os.MkdirTemp("", "test_template_*")
		if err != nil {
			t.Fatal(err)
		}
		defer os.RemoveAll(tmpDir)

		path := filepath.Join(tmpDir, "config.sh.template")
		content := "echo hi"
		if err := os.WriteFile(path, []byte(content), 0644); err != nil {
			t.Fatal(err)
		}

		res, err := EnforceFile(path, 2026, "Google LLC", "Apache-2.0", "full")
		if err != nil {
			t.Fatal(err)
		}
		if !res.LicenseAdded {
			t.Error("EnforceFile() failed to add license to .template file")
		}

		data, _ := os.ReadFile(path)
		if !strings.HasPrefix(string(data), "# Copyright") {
			t.Error("EnforceFile() did not use # for .sh.template")
		}
	})

	t.Run("resolves_tmpl_extensions", func(t *testing.T) {
		tmpDir, err := os.MkdirTemp("", "test_tmpl_*")
		if err != nil {
			t.Fatal(err)
		}
		defer os.RemoveAll(tmpDir)

		path := filepath.Join(tmpDir, "config.xml.tmpl")
		content := "<root/>"
		if err := os.WriteFile(path, []byte(content), 0644); err != nil {
			t.Fatal(err)
		}

		res, err := EnforceFile(path, 2026, "Google LLC", "Apache-2.0", "full")
		if err != nil {
			t.Fatal(err)
		}
		if !res.LicenseAdded {
			t.Error("EnforceFile() failed to add license to .tmpl file")
		}

		data, _ := os.ReadFile(path)
		if !strings.HasPrefix(string(data), "<!--") {
			t.Error("EnforceFile() did not use <!-- for .xml.tmpl")
		}
	})
}

func TestCStyleSlashSlashFormatting(t *testing.T) {
	f := HeaderFormatter{}
	text := "SPDX-FileCopyrightText: 2026 Author\nSPDX-License-Identifier: Apache-2.0"

	t.Run("ts_prefers_double_slash_for_spdx", func(t *testing.T) {
		got := f.FormatWithStyle(text, "ts", "spdx")
		want := "// SPDX-FileCopyrightText: 2026 Author\n// SPDX-License-Identifier: Apache-2.0\n\n"
		if got != want {
			t.Errorf("FormatWithStyle() = %q, want %q", got, want)
		}
	})

	t.Run("css_retains_block_for_spdx", func(t *testing.T) {
		got := f.FormatWithStyle(text, "css", "spdx")
		if !strings.HasPrefix(got, "/**") || !strings.HasSuffix(got, "*/\n\n") {
			t.Errorf("FormatWithStyle(css) should use block comments, got %q", got)
		}
	})

	t.Run("ts_uses_block_for_full", func(t *testing.T) {
		got := f.FormatWithStyle(text, "ts", "full")
		if !strings.HasPrefix(got, "/**") {
			t.Errorf("FormatWithStyle(ts, full) should use block comments, got %q", got)
		}
	})
}

func TestIdempotentCBlockConversion(t *testing.T) {
	content := "/**\n * SPDX-FileCopyrightText: 2026 Author\n * SPDX-License-Identifier: Apache-2.0\n */\n\nfunction test() {}\n"

	// Pass 1: Converts /** */ to //
	got1, res1 := ProcessFileContent(content, "ts", 2026, "Author", "Apache-2.0", "spdx")
	if !res1.Modified {
		t.Errorf("Pass 1: expected Modified = true, got false")
	}
	expectedHeader := "// SPDX-FileCopyrightText: 2026 Author\n// SPDX-License-Identifier: Apache-2.0\n\nfunction test() {}\n"
	if got1 != expectedHeader {
		t.Errorf("Pass 1: got %q, want %q", got1, expectedHeader)
	}

	// Pass 2: Running again on got1 must result in zero modifications (idempotent)
	got2, res2 := ProcessFileContent(got1, "ts", 2026, "Author", "Apache-2.0", "spdx")
	if res2.Modified {
		t.Errorf("Pass 2: expected Modified = false for idempotent execution, got true")
	}
	if got2 != got1 {
		t.Errorf("Pass 2: content changed between idempotent passes")
	}
}

func TestAcceptableLicenses(t *testing.T) {
	mitContent := "// SPDX-FileCopyrightText: 2026 ThirdParty\n// SPDX-License-Identifier: MIT\n\nfunction helper() {}"

	t.Run("fails_and_does_not_modify_when_license_unacceptable", func(t *testing.T) {
		got, res := ProcessFileContent(mitContent, "ts", 2026, "Author", "Apache-2.0", "spdx")
		if res.UnacceptableLicense != "MIT" {
			t.Errorf("expected UnacceptableLicense = 'MIT', got %q", res.UnacceptableLicense)
		}
		if res.Modified {
			t.Error("file with unacceptable license should NOT be modified")
		}
		if got != mitContent {
			t.Error("content was altered despite unacceptable license")
		}
	})

	t.Run("passes_and_does_not_modify_when_license_is_acceptable", func(t *testing.T) {
		got, res := ProcessFileContent(mitContent, "ts", 2026, "Author", "Apache-2.0", "spdx", "MIT", "BSD-3-Clause")
		if res.UnacceptableLicense != "" {
			t.Errorf("expected empty UnacceptableLicense, got %q", res.UnacceptableLicense)
		}
		if res.Modified {
			t.Error("file with acceptable foreign license should NOT be overwritten")
		}
		if got != mitContent {
			t.Error("content was altered despite being an acceptable license")
		}
	})
}

func TestParseLicenseList(t *testing.T) {
	tests := []struct {
		input string
		want  []string
	}{
		{"MIT, BSD-3-Clause, Apache-2.0", []string{"MIT", "BSD-3-Clause", "Apache-2.0"}},
		{"MIT BSD-2-Clause   GPL-2.0-only", []string{"MIT", "BSD-2-Clause", "GPL-2.0-only"}},
		{"", nil},
	}

	for _, tt := range tests {
		got := ParseLicenseList(tt.input)
		if len(got) != len(tt.want) {
			t.Fatalf("ParseLicenseList(%q) len = %d, want %d", tt.input, len(got), len(tt.want))
		}
		for i := range got {
			if got[i] != tt.want[i] {
				t.Errorf("got[%d] = %q, want %q", i, got[i], tt.want[i])
			}
		}
	}
}
