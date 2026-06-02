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

// Package licensing provides utilities for managing license headers in source files.
package licensing

import (
	"bytes"
	"embed"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

var (
	// HashStyleExtensions defines extensions that use '#' for comments.
	HashStyleExtensions = []string{"bash", "bats", "conf", "desktop", "dockerfile", "list", "py", "sh", "yaml", "yml"}

	// HTMLStyleExtensions defines extensions that use '<!-- -->' for comments.
	HTMLStyleExtensions = []string{"html", "md", "xml"}

	// CStyleExtensions defines extensions that use '/** */' for comments.
	CStyleExtensions = []string{"cjs", "css", "go", "js", "jsx", "mjs", "ts", "tsx"}

	//go:embed assets/*.txt
	licenseAssets embed.FS

	// Licenses contains the full text of supported licenses.
	Licenses = make(map[string]string)

	reC    = regexp.MustCompile(`(?s)/\*\*\s*\n(?:\s*\*?\s*Copyright.*?\n)+\s*\*/(?:\s*\n)?`)
	reHTML = regexp.MustCompile(`(?s)<!--\s*\n\s*Copyright.*?\n\s*-->(?:\s*\n)?`)

	reShebang = regexp.MustCompile(`(?m)^(#!.*?\n)\n*(# Copyright)`)

	reFrontmatter = regexp.MustCompile(`(?s)^---\n.*?\n---\n+`)

	holderRegex = regexp.MustCompile(`(?m)^(?:\s*//|\s*#|\s*\*|<!--)\s*Copyright\s+[0-9]{4}(?:-[0-9]{4})?\s+(.*?)(?:\n|$)`)
)

func init() {
	files, err := fs.ReadDir(licenseAssets, "assets")
	if err != nil {
		panic(fmt.Errorf("failed to read embedded license assets: %w", err))
	}

	for _, f := range files {
		if !f.IsDir() && strings.HasSuffix(f.Name(), ".txt") {
			content, err := fs.ReadFile(licenseAssets, "assets/"+f.Name())
			if err != nil {
				panic(fmt.Errorf("failed to read embedded license file %s: %w", f.Name(), err))
			}
			licenseID := strings.TrimSuffix(f.Name(), ".txt")
			Licenses[licenseID] = string(content)
		}
	}
}

// HeaderFormatter formats the license text for different file types.
type HeaderFormatter struct{}

// Format wraps text in comment markers based on file extension.
func (f HeaderFormatter) Format(text string, ext string) string {
	text = strings.TrimSpace(text)
	lines := strings.Split(text, "\n")

	if contains(HashStyleExtensions, ext) {
		var formatted []string
		for _, line := range lines {
			if line == "" {
				formatted = append(formatted, "#")
			} else {
				formatted = append(formatted, "# "+line)
			}
		}
		return strings.Join(formatted, "\n") + "\n\n"
	}

	if contains(HTMLStyleExtensions, ext) {
		return "<!--\n" + text + "\n-->\n\n"
	}

	if contains(CStyleExtensions, ext) {
		var formatted []string
		formatted = append(formatted, "/**")
		for _, line := range lines {
			if line == "" {
				formatted = append(formatted, " *")
			} else {
				formatted = append(formatted, " * "+line)
			}
		}
		formatted = append(formatted, " */")
		return strings.Join(formatted, "\n") + "\n\n"
	}

	return ""
}

func contains(slice []string, s string) bool {
	for _, item := range slice {
		if item == s {
			return true
		}
	}
	return false
}

// Result represents the outcome of processing a file.
type Result struct {
	Modified        bool
	LicenseAdded    bool
	YearUpdated     bool
	DifferentHolder string
}

// ProcessFileContent processes the file content to ensure license compliance.
func ProcessFileContent(content string, ext string, currentYear int, holder string, targetLicense string) (string, Result) {
	res := Result{}
	originalContent := content

	// 0. Extract YAML frontmatter if present
	var frontmatter string
	var hasMetadataLicense bool
	if strings.HasPrefix(content, "---") {
		if match := reFrontmatter.FindString(content); match != "" {
			frontmatter = match
			content = content[len(frontmatter):]
			// Check for license: key in the frontmatter block
			if strings.Contains(frontmatter, "\nlicense:") {
				hasMetadataLicense = true
			}
		}
	}

	// New Requirement: An existing header must never be removed.
	// We only proceed if we actually know how to format a header for this extension.
	if formatter := (HeaderFormatter{}); formatter.Format("test", ext) == "" {
		return originalContent, res
	}

	res.DifferentHolder = checkForeignHolders(content, holder)
	if res.DifferentHolder != "" {
		return originalContent, res
	}

	startYear := getOriginalCopyrightYear(content, holder, currentYear)
	content = StripRedundantHeaders(content)

	// 1. Check for full license string
	licenseText, ok := Licenses[targetLicense]
	if ok && !hasMetadataLicense && !strings.Contains(content, strings.Split(licenseText, "\n")[0]) {
		effectiveYear := strconv.Itoa(currentYear)
		if startYear < currentYear {
			effectiveYear = fmt.Sprintf("%d-%d", startYear, currentYear)
		}
		fullHeaderText := fmt.Sprintf("Copyright %s %s\n\n%s", effectiveYear, holder, licenseText)
		formatter := HeaderFormatter{}
		formattedHeader := formatter.Format(fullHeaderText, ext)

		if formattedHeader != "" {
			res.LicenseAdded = true
			if (ext == "sh" || ext == "bash" || ext == "bats" || ext == "py") && strings.HasPrefix(content, "#!") {
				lines := strings.SplitAfterN(content, "\n", 2)
				if len(lines) > 1 {
					content = lines[0] + "\n" + formattedHeader + lines[1]
				} else {
					content = lines[0] + "\n" + formattedHeader
				}
			} else {
				content = formattedHeader + content
			}
		}
	}

	// 2. Update copyright year to range if in the past
	quotedHolder := regexp.QuoteMeta(holder)
	specificYearRegex := regexp.MustCompile(`(?i)Copyright\s+([0-9]{4})(?:-[0-9]{4})?\s+` + quotedHolder)
	content = specificYearRegex.ReplaceAllStringFunc(content, func(match string) string {
		submatch := specificYearRegex.FindStringSubmatch(match)
		if len(submatch) > 1 {
			matchStartYear, _ := strconv.Atoi(submatch[1])
			if matchStartYear < currentYear {
				res.YearUpdated = true
				return fmt.Sprintf("Copyright %d-%d %s", matchStartYear, currentYear, holder)
			}
		}
		return match
	})

	// 3. Final cleanup and spacing
	content = strings.TrimLeft(content, "\n")

	// Spacing logic (simplified version of the Python regexes)
	// go/keep-sorted start
	endMarkers := []string{
		`02110-1301,\s+USA\.`,
		`DEALINGS\s+IN\s+THE\s+SOFTWARE\.`,
		`limitations\s+under\s+the\s+License\.`,
	}
	// go/keep-sorted end
	endPattern := `(` + strings.Join(endMarkers, "|") + `)`

	if contains(HashStyleExtensions, ext) {
		content = reShebang.ReplaceAllString(content, "${1}\n${2}")

		reEnd := regexp.MustCompile(`(?m)(# ` + endPattern + `)\n+`)
		content = reEnd.ReplaceAllString(content, "${1}\n\n")
	} else if contains(HTMLStyleExtensions, ext) {
		reEnd := regexp.MustCompile(`(?m)(` + endPattern + `\n-->)\n+`)
		content = reEnd.ReplaceAllString(content, "${1}\n\n")
	} else if contains(CStyleExtensions, ext) {
		reEnd := regexp.MustCompile(`(?m)(` + endPattern + `\n\s*\*/)\n+`)
		content = reEnd.ReplaceAllString(content, "${1}\n\n")
	}

	content = strings.TrimRight(content, " \n\r\t")
	if content != "" {
		content += "\n"
	}

	content = frontmatter + content
	res.Modified = content != originalContent
	return content, res
}

// StripRedundantHeaders removes short or malformed headers before re-applying the full one.
func StripRedundantHeaders(content string) string {
	content = reC.ReplaceAllString(content, "")
	content = reHTML.ReplaceAllString(content, "")
	return content
}

func getOriginalCopyrightYear(content string, holder string, currentYear int) int {
	quotedHolder := regexp.QuoteMeta(holder)
	specificYearRegex := regexp.MustCompile(`(?i)Copyright\s+([0-9]{4})(?:-[0-9]{4})?\s+` + quotedHolder)
	match := specificYearRegex.FindStringSubmatch(content)
	if len(match) > 1 {
		year, _ := strconv.Atoi(match[1])
		return year
	}
	return currentYear
}

func checkForeignHolders(content string, targetHolder string) string {
	matches := holderRegex.FindAllStringSubmatch(content, -1)
	for _, match := range matches {
		if len(match) > 1 {
			foundHolder := strings.TrimSpace(match[1])
			if !strings.Contains(strings.ToLower(foundHolder), strings.ToLower(targetHolder)) {
				return foundHolder
			}
		}
	}
	return ""
}

// EnforceFile reads a file, applies licensing, and writes it back if changed.
func EnforceFile(path string, currentYear int, holder string, targetLicense string) (Result, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Result{}, err
	}

	if len(data) > 0 && bytes.IndexByte(data, 0) != -1 {
		return Result{}, nil
	}

	content := string(data)
	ext := strings.ToLower(strings.TrimPrefix(filepath.Ext(path), "."))

	// Resolve templates (e.g., config.sh.template -> sh, config.sh.tmpl -> sh)
	if ext == "template" || ext == "tmpl" {
		base := strings.TrimSuffix(filepath.Base(path), "."+ext)
		ext = strings.ToLower(strings.TrimPrefix(filepath.Ext(base), "."))
	}

	if ext == "" && filepath.Base(path) == "Dockerfile" {
		ext = "dockerfile"
	}

	newContent, res := ProcessFileContent(content, ext, currentYear, holder, targetLicense)

	if res.Modified {
		err = os.WriteFile(path, []byte(newContent), 0644)
		if err != nil {
			return Result{}, err
		}
	}

	return res, nil
}
