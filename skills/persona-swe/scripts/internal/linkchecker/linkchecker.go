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

// Package linkchecker provides functions to scan markdown files for broken relative links.
package linkchecker

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/yuin/goldmark"
	"github.com/yuin/goldmark/ast"
	"github.com/yuin/goldmark/text"
)

// BrokenLink represents a detected broken link.
type BrokenLink struct {
	LineNum      int
	Link         string
	ResolvedPath string
}

// FileResult stores the scan results for a single file.
type FileResult struct {
	FilePath    string
	BrokenLinks []BrokenLink
}

// IsRelativeLink checks if a link is a relative file path.
func IsRelativeLink(link string) bool {
	if link == "" {
		return false
	}
	// Ignore web links, mailto, anchors, and protocols
	if strings.HasPrefix(link, "http://") ||
		strings.HasPrefix(link, "https://") ||
		strings.HasPrefix(link, "mailto:") ||
		strings.HasPrefix(link, "tel:") ||
		strings.HasPrefix(link, "#") ||
		strings.HasPrefix(link, "chrome-extension://") ||
		strings.HasPrefix(link, "file://") {
		return false
	}
	return true
}

// CleanLink removes anchor queries or parameters from the link.
func CleanLink(link string) string {
	// Remove anchor
	if idx := strings.Index(link, "#"); idx != -1 {
		link = link[:idx]
	}
	// Remove query params
	if idx := strings.Index(link, "?"); idx != -1 {
		link = link[:idx]
	}
	return strings.TrimSpace(link)
}

// CheckFile parses the markdown file, extracts relative links, and verifies their existence.
func CheckFile(path string, repoRoot string) ([]BrokenLink, error) {
	source, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read file: %w", err)
	}

	md := goldmark.New()
	doc := md.Parser().Parse(text.NewReader(source))

	var brokenLinks []BrokenLink
	fileDir := filepath.Dir(path)

	err = ast.Walk(doc, func(node ast.Node, entering bool) (ast.WalkStatus, error) {
		if !entering {
			return ast.WalkContinue, nil
		}

		var dest []byte
		switch n := node.(type) {
		case *ast.Link:
			dest = n.Destination
		case *ast.Image:
			dest = n.Destination
		}

		if len(dest) == 0 {
			return ast.WalkContinue, nil
		}

		rawLink := string(dest)
		if !IsRelativeLink(rawLink) {
			return ast.WalkContinue, nil
		}

		link := CleanLink(rawLink)
		if link == "" {
			return ast.WalkContinue, nil
		}

		var resolvedPath string
		if strings.HasPrefix(link, "/") {
			resolvedPath = filepath.Join(repoRoot, link)
		} else {
			resolvedPath = filepath.Join(fileDir, link)
		}

		// Check if exists
		if _, err := os.Stat(resolvedPath); os.IsNotExist(err) {
			lineNum := 1
			offset := node.Pos()

			if offset >= 0 && offset < len(source) {
				lineNum = bytes.Count(source[:offset], []byte("\n")) + 1
			}

			brokenLinks = append(brokenLinks, BrokenLink{
				LineNum:      lineNum,
				Link:         rawLink,
				ResolvedPath: resolvedPath,
			})
		}

		return ast.WalkContinue, nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to walk AST: %w", err)
	}

	return brokenLinks, nil
}


