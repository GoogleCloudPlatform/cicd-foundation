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
	"crypto/sha256"
	"encoding/hex"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

var (
	spdxTagRegex       = regexp.MustCompile(`(?i)SPDX-License-Identifier:\s*([A-Za-z0-9.-]+)`)
	copyrightLineRegex = regexp.MustCompile(`(?i)copyright\s+(\(c\)\s*)?([0-9]{4}[,\s-]*)?.*`)
	whitespaceRegex    = regexp.MustCompile(`\s+`)
)

// FindRepoRoot attempts to discover the repository root directory.
func FindRepoRoot() string {
	cmd := exec.Command("git", "rev-parse", "--show-toplevel")
	if out, err := cmd.Output(); err == nil {
		root := strings.TrimSpace(string(out))
		if root != "" {
			return root
		}
	}

	dir, err := os.Getwd()
	if err != nil {
		return "."
	}

	for {
		for _, name := range []string{".git", "LICENSE", "LICENSE.txt", "LICENSE.md"} {
			if _, err := os.Stat(filepath.Join(dir, name)); err == nil {
				return dir
			}
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}

	return "."
}

// NormalizeLicenseText cleans up license text for deterministic hashing.
func NormalizeLicenseText(content string) string {
	content = strings.ReplaceAll(content, "\r\n", "\n")
	content = copyrightLineRegex.ReplaceAllString(content, "")
	content = whitespaceRegex.ReplaceAllString(content, " ")
	return strings.TrimSpace(strings.ToLower(content))
}

// ComputeHash computes the SHA-256 hash of normalized text.
func ComputeHash(text string) string {
	h := sha256.Sum256([]byte(text))
	return hex.EncodeToString(h[:])
}

// MapLicenseTextToSPDX detects the SPDX license identifier from license file content.
// It uses a multi-tiered strategy:
// 1. Embedded SPDX tag
// 2. Structural legal clause fingerprinting
// 3. Known license signature matching
func MapLicenseTextToSPDX(content string) string {
	if match := spdxTagRegex.FindStringSubmatch(content); len(match) > 1 {
		return match[1]
	}

	lower := strings.ToLower(content)

	// Clause fingerprinting
	if strings.Contains(lower, "apache license") &&
		(strings.Contains(lower, "version 2.0") || strings.Contains(lower, "http://www.apache.org/licenses/license-2.0")) {
		return "Apache-2.0"
	}

	if strings.Contains(lower, "permission is hereby granted, free of charge") &&
		strings.Contains(lower, "without warranty of any kind") {
		return "MIT"
	}

	if strings.Contains(lower, "redistribution and use in source and binary forms") {
		if strings.Contains(lower, "neither the name of") || strings.Contains(lower, "neither the name of the copyright holder") {
			return "BSD-3-Clause"
		}
		return "BSD-2-Clause"
	}

	if strings.Contains(lower, "gnu general public license") {
		if strings.Contains(lower, "version 3") {
			return "GPL-3.0-only"
		}
		if strings.Contains(lower, "version 2") {
			return "GPL-2.0-only"
		}
	}

	if strings.Contains(lower, "mozilla public license") && strings.Contains(lower, "version 2.0") {
		return "MPL-2.0"
	}

	if strings.Contains(lower, "cc0 1.0 universal") || strings.Contains(lower, "public domain dedication") {
		return "CC0-1.0"
	}

	return ""
}

// DiscoverDefaultLicense scans the repository root for a LICENSE or LICENSE.txt file
// and resolves its SPDX identifier. Defaults to "Apache-2.0" if unrecognized or absent.
func DiscoverDefaultLicense() string {
	root := FindRepoRoot()
	for _, name := range []string{"LICENSE", "LICENSE.txt", "LICENSE.md", "COPYING"} {
		path := filepath.Join(root, name)
		data, err := os.ReadFile(path)
		if err == nil {
			if spdxID := MapLicenseTextToSPDX(string(data)); spdxID != "" {
				return spdxID
			}
		}
	}
	return "Apache-2.0"
}
