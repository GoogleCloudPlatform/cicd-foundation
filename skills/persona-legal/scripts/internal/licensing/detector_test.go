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
	"testing"
)

func TestMapLicenseTextToSPDX(t *testing.T) {
	tests := []struct {
		name    string
		content string
		want    string
	}{
		{
			name:    "spdx_tag",
			content: "Some text\nSPDX-License-Identifier: MIT\nmore text",
			want:    "MIT",
		},
		{
			name:    "apache_2",
			content: "Apache License\nVersion 2.0, January 2004\nhttp://www.apache.org/licenses/",
			want:    "Apache-2.0",
		},
		{
			name:    "mit",
			content: "Permission is hereby granted, free of charge, to any person...\nWITHOUT WARRANTY OF ANY KIND",
			want:    "MIT",
		},
		{
			name:    "bsd_3_clause",
			content: "Redistribution and use in source and binary forms...\nNeither the name of the copyright holder nor the names of its contributors...",
			want:    "BSD-3-Clause",
		},
		{
			name:    "bsd_2_clause",
			content: "Redistribution and use in source and binary forms...\nRedistributions in binary form must reproduce...",
			want:    "BSD-2-Clause",
		},
		{
			name:    "gpl_3",
			content: "GNU GENERAL PUBLIC LICENSE\nVersion 3, 29 June 2007",
			want:    "GPL-3.0-only",
		},
		{
			name:    "gpl_2",
			content: "GNU GENERAL PUBLIC LICENSE\nVersion 2, June 1991",
			want:    "GPL-2.0-only",
		},
		{
			name:    "mpl_2",
			content: "Mozilla Public License\nVersion 2.0",
			want:    "MPL-2.0",
		},
		{
			name:    "cc0",
			content: "CC0 1.0 Universal\nPublic Domain Dedication",
			want:    "CC0-1.0",
		},
		{
			name:    "unknown",
			content: "Custom Proprietary License - Do Not Distribute",
			want:    "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := MapLicenseTextToSPDX(tt.content)
			if got != tt.want {
				t.Errorf("MapLicenseTextToSPDX() = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestDiscoverDefaultLicense(t *testing.T) {
	// The repo root has an Apache-2.0 LICENSE file
	detected := DiscoverDefaultLicense()
	if detected != "Apache-2.0" {
		t.Errorf("DiscoverDefaultLicense() = %q, want 'Apache-2.0'", detected)
	}
}

func TestDiscoverDefaultLicenseWithTemp(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "test_detector_*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	mitContent := "Permission is hereby granted, free of charge, to any person...\nWITHOUT WARRANTY OF ANY KIND"
	if err := os.WriteFile(filepath.Join(tmpDir, "LICENSE"), []byte(mitContent), 0644); err != nil {
		t.Fatal(err)
	}

	spdxID := MapLicenseTextToSPDX(mitContent)
	if spdxID != "MIT" {
		t.Errorf("expected MIT, got %q", spdxID)
	}
}
