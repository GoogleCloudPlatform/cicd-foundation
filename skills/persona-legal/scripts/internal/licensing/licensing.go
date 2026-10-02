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
	"unicode"
)

var (
	// HashStyleExtensions defines extensions that use '#' for comments.
	HashStyleExtensions = []string{
		// go/keep-sorted start
		"bash",
		"bats",
		"conf",
		"desktop",
		"dockerfile",
		"env",
		"hcl",
		"ini",
		"list",
		"makefile",
		"mk",
		"py",
		"rb",
		"sh",
		"tf",
		"tfvars",
		"toml",
		"yaml",
		"yml",
		// go/keep-sorted end
	}

	// HTMLStyleExtensions defines extensions that use '<!-- -->' for comments.
	HTMLStyleExtensions = []string{
		// go/keep-sorted start
		"html",
		"md",
		"svg",
		"xml",
		// go/keep-sorted end
	}

	// CStyleExtensions defines extensions that use '/** */' or '//' for comments.
	CStyleExtensions = []string{
		// go/keep-sorted start
		"c",
		"cjs",
		"cpp",
		"cs",
		"css",
		"go",
		"h",
		"hpp",
		"java",
		"js",
		"jsx",
		"kt",
		"mjs",
		"php",
		"rs",
		"scala",
		"swift",
		"ts",
		"tsx",
		// go/keep-sorted end
	}

	//go:embed assets/*.txt
	licenseAssets embed.FS

	// Licenses contains the full text of supported licenses.
	Licenses = make(map[string]string)

	reC    = regexp.MustCompile(`(?s)/\*\*\s*\n(?:\s*\*?\s*Copyright.*?\n)+\s*\*/(?:\s*\n)?`)
	reHTML = regexp.MustCompile(`(?s)<!--\s*\n\s*Copyright.*?\n\s*-->(?:\s*\n)?`)

	reCBlockHeader = regexp.MustCompile(`(?s)/\*\*\s*\n(?:\s*\*?\s*(?:SPDX-FileCopyrightText:|SPDX-License-Identifier:|Copyright|Licensed under).*?\n)+\s*\*/(?:\s*\n)?`)

	rePrologueSpacing = regexp.MustCompile(`(?i)^((?:#!|<\?xml|<\?php|<!doctype).*?\n)\n*(#|<!--|/\*\*|//)`)

	reFrontmatter        = regexp.MustCompile(`(?s)^---\n.*?\n---\n+`)
	reFrontmatterLicense = regexp.MustCompile(`(?m)^license:\s*([A-Za-z0-9.-]+)`)

	reSPDXTag = regexp.MustCompile(`(?i)SPDX-License-Identifier:\s*([A-Za-z0-9.-]+)`)

	holderRegex = regexp.MustCompile(`(?m)^(?:\s*//|\s*#|\s*\*|<!--)\s*(?:Copyright|SPDX-FileCopyrightText:)\s+([0-9]{4})(?:-[0-9]{4})?\s+(.*?)(?:\n|$)`)
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

// DefaultFilter generates the default regular expression to filter files based on the supported extensions.
func DefaultFilter() string {
	var allExtensions []string
	allExtensions = append(allExtensions, HashStyleExtensions...)
	allExtensions = append(allExtensions, HTMLStyleExtensions...)
	allExtensions = append(allExtensions, CStyleExtensions...)

	var exts []string
	var specialFiles []string
	for _, ext := range allExtensions {
		if ext == "dockerfile" {
			specialFiles = append(specialFiles, "^Dockerfile$")
		} else if ext == "makefile" {
			specialFiles = append(specialFiles, "^Makefile$")
		} else {
			exts = append(exts, ext)
		}
	}
	// 'template' and 'tmpl' are resolved dynamically to their base file type
	exts = append(exts, "template", "tmpl")

	regex := `\.(` + strings.Join(exts, "|") + `)$`
	if len(specialFiles) > 0 {
		regex += `|` + strings.Join(specialFiles, "|")
	}
	return regex
}

// ParseLicenseList parses a comma- or space-separated string of SPDX identifiers.
func ParseLicenseList(input string) []string {
	fields := strings.FieldsFunc(input, func(r rune) bool {
		return r == ',' || unicode.IsSpace(r)
	})
	var result []string
	for _, f := range fields {
		trimmed := strings.TrimSpace(f)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

// IsLicenseAcceptable checks whether a detected license matches the target license or any acceptable license.
func IsLicenseAcceptable(detected string, primary string, acceptable []string) bool {
	if strings.EqualFold(detected, primary) {
		return true
	}
	for _, acc := range acceptable {
		if strings.EqualFold(detected, acc) {
			return true
		}
	}
	return false
}

// extractLeadingHeader extracts the comment block at the top of the file before any code.
func extractLeadingHeader(content string) string {
	lower := strings.ToLower(content)
	if strings.HasPrefix(content, "#!") ||
		strings.HasPrefix(lower, "<?xml") ||
		strings.HasPrefix(lower, "<?php") ||
		strings.HasPrefix(lower, "<!doctype") {
		parts := strings.SplitAfterN(content, "\n", 2)
		if len(parts) > 1 {
			content = parts[1]
		}
	}

	content = strings.TrimLeft(content, " \t\r\n")

	// Block comments: /* ... */ or /** ... */
	if strings.HasPrefix(content, "/*") {
		endIdx := strings.Index(content, "*/")
		if endIdx != -1 {
			return content[:endIdx+2]
		}
	}

	// HTML comments: <!-- ... -->
	if strings.HasPrefix(content, "<!--") {
		endIdx := strings.Index(content, "-->")
		if endIdx != -1 {
			return content[:endIdx+3]
		}
	}

	// Line comments: // or #
	lines := strings.Split(content, "\n")
	var headerLines []string
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			headerLines = append(headerLines, line)
			continue
		}
		if strings.HasPrefix(trimmed, "//") || strings.HasPrefix(trimmed, "#") {
			headerLines = append(headerLines, line)
			continue
		}
		break
	}

	return strings.Join(headerLines, "\n")
}

// DetectExistingLicense inspects content to identify an existing license identifier in the file header.
func DetectExistingLicense(content string) string {
	if strings.HasPrefix(content, "---") {
		if match := reFrontmatter.FindString(content); match != "" {
			if licMatch := reFrontmatterLicense.FindStringSubmatch(match); len(licMatch) > 1 {
				return licMatch[1]
			}
		}
	}

	header := extractLeadingHeader(content)
	if match := reSPDXTag.FindStringSubmatch(header); len(match) > 1 {
		return match[1]
	}
	for licID, text := range Licenses {
		lines := strings.Split(text, "\n")
		if len(lines) > 0 && lines[0] != "" && strings.Contains(header, lines[0]) {
			return licID
		}
	}
	return ""
}

// HeaderFormatter formats the license text for different file types.
type HeaderFormatter struct{}

// Format wraps text in comment markers based on file extension using full formatting by default.
func (f HeaderFormatter) Format(text string, ext string) string {
	return f.FormatWithStyle(text, ext, "full")
}

// FormatWithStyle wraps text in comment markers based on file extension and format style ("spdx" or "full").
func (f HeaderFormatter) FormatWithStyle(text string, ext string, formatStyle string) string {
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
		if formatStyle == "spdx" && ext != "css" {
			var formatted []string
			for _, line := range lines {
				if line == "" {
					formatted = append(formatted, "//")
				} else {
					formatted = append(formatted, "// "+line)
				}
			}
			return strings.Join(formatted, "\n") + "\n\n"
		}

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
	Modified            bool
	LicenseAdded        bool
	YearUpdated         bool
	DifferentHolder     string
	UnacceptableLicense string
}

// convertCBlockToSlashSlash converts a /** */ comment block to // line comments.
func convertCBlockToSlashSlash(content string) (string, bool) {
	match := reCBlockHeader.FindString(content)
	if match == "" {
		return content, false
	}

	lines := strings.Split(match, "\n")
	var convertedLines []string
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "/**" || trimmed == "*/" || trimmed == "" {
			continue
		}
		trimmed = strings.TrimPrefix(trimmed, "*")
		trimmed = strings.TrimSpace(trimmed)
		if trimmed == "" {
			convertedLines = append(convertedLines, "//")
		} else {
			convertedLines = append(convertedLines, "// "+trimmed)
		}
	}

	if len(convertedLines) == 0 {
		return content, false
	}

	replacement := strings.Join(convertedLines, "\n") + "\n\n"
	newContent := strings.Replace(content, match, replacement, 1)
	return newContent, newContent != content
}

// ProcessFileContent processes the file content to ensure license compliance.
func ProcessFileContent(content string, ext string, currentYear int, holder string, targetLicense string, format string, acceptableLicenses ...string) (string, Result) {
	res := Result{}
	originalContent := content

	// 0. Extract YAML frontmatter if present
	var frontmatter string
	var hasMetadataLicense bool
	if strings.HasPrefix(content, "---") {
		if match := reFrontmatter.FindString(content); match != "" {
			frontmatter = match
			content = content[len(frontmatter):]
			if strings.Contains(frontmatter, "\nlicense:") {
				hasMetadataLicense = true
			}
		}
	}

	// Verify we know how to format a header for this extension.
	if formatter := (HeaderFormatter{}); formatter.FormatWithStyle("test", ext, format) == "" {
		return originalContent, res
	}

	// 1. License Check Gate: verify existing license against acceptable set
	detectedLic := DetectExistingLicense(originalContent)
	if detectedLic != "" {
		if !IsLicenseAcceptable(detectedLic, targetLicense, acceptableLicenses) {
			res.UnacceptableLicense = detectedLic
			return originalContent, res
		}
		// Acceptable license from another vendor/project: do not alter or overwrite
		if !strings.EqualFold(detectedLic, targetLicense) {
			return originalContent, res
		}
	}

	// 2. Foreign copyright holder check
	res.DifferentHolder = checkForeignHolders(content, holder)
	if res.DifferentHolder != "" {
		return originalContent, res
	}

	// 3. Idempotent conversion of /** */ to // for CStyleExtensions in SPDX mode
	if format == "spdx" && contains(CStyleExtensions, ext) && ext != "css" {
		if converted, changed := convertCBlockToSlashSlash(content); changed {
			content = converted
			res.Modified = true
		}
	}

	startYear := getOriginalCopyrightYear(content, holder, currentYear)
	content = StripRedundantHeaders(content)

	// 4. Check for full license string or SPDX identifier
	licenseText := Licenses[targetLicense]
	hasLicenseIdentifier := strings.Contains(content, fmt.Sprintf("SPDX-License-Identifier: %s", targetLicense))
	needsLicense := !hasMetadataLicense

	if format == "spdx" {
		needsLicense = needsLicense && !hasLicenseIdentifier
	} else if licenseText != "" {
		needsLicense = needsLicense && !strings.Contains(content, strings.Split(licenseText, "\n")[0])
	} else {
		needsLicense = false
	}

	if needsLicense {
		effectiveYear := strconv.Itoa(currentYear)
		if startYear < currentYear {
			effectiveYear = fmt.Sprintf("%d-%d", startYear, currentYear)
		}

		var fullHeaderText string
		if format == "spdx" {
			fullHeaderText = fmt.Sprintf("SPDX-FileCopyrightText: %s %s\nSPDX-License-Identifier: %s", effectiveYear, holder, targetLicense)
		} else {
			fullHeaderText = fmt.Sprintf("Copyright %s %s\n\n%s", effectiveYear, holder, licenseText)
		}

		formatter := HeaderFormatter{}
		formattedHeader := formatter.FormatWithStyle(fullHeaderText, ext, format)

		if formattedHeader != "" {
			res.LicenseAdded = true
			// Move prologues (shebangs, xml/php tags, html doctypes) above the license header
			lowerContent := strings.ToLower(content)
			if strings.HasPrefix(content, "#!") ||
				strings.HasPrefix(lowerContent, "<?xml") ||
				strings.HasPrefix(lowerContent, "<?php") ||
				strings.HasPrefix(lowerContent, "<!doctype") {
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

	// 5. Update copyright year to range if in the past
	quotedHolder := regexp.QuoteMeta(holder)
	specificYearRegex := regexp.MustCompile(`(?i)(Copyright|SPDX-FileCopyrightText:)\s+([0-9]{4})(?:-[0-9]{4})?\s+` + quotedHolder)
	content = specificYearRegex.ReplaceAllStringFunc(content, func(match string) string {
		submatch := specificYearRegex.FindStringSubmatch(match)
		if len(submatch) > 2 {
			prefix := submatch[1]
			matchStartYear, _ := strconv.Atoi(submatch[2])
			if matchStartYear < currentYear {
				res.YearUpdated = true
				return fmt.Sprintf("%s %d-%d %s", prefix, matchStartYear, currentYear, holder)
			}
		}
		return match
	})

	// 6. Spacing logic
	content = strings.TrimLeft(content, "\n")

	// go/keep-sorted start
	endMarkers := []string{
		`02110-1301,\s+USA\.`,
		`DEALINGS\s+IN\s+THE\s+SOFTWARE\.`,
		`limitations\s+under\s+the\s+License\.`,
		`SPDX-License-Identifier:.*?`,
	}
	// go/keep-sorted end
	endPattern := `(` + strings.Join(endMarkers, "|") + `)`

	content = rePrologueSpacing.ReplaceAllString(content, "${1}\n${2}")

	if contains(HashStyleExtensions, ext) {
		reEnd := regexp.MustCompile(`(?m)(# ` + endPattern + `)\n+`)
		content = reEnd.ReplaceAllString(content, "${1}\n\n")
	} else if contains(HTMLStyleExtensions, ext) {
		reEnd := regexp.MustCompile(`(?m)(` + endPattern + `\n-->)\n+`)
		content = reEnd.ReplaceAllString(content, "${1}\n\n")
	} else if contains(CStyleExtensions, ext) {
		if format == "spdx" && ext != "css" {
			reEnd := regexp.MustCompile(`(?m)(// ` + endPattern + `)\n+`)
			content = reEnd.ReplaceAllString(content, "${1}\n\n")
		} else {
			reEnd := regexp.MustCompile(`(?m)(` + endPattern + `\n\s*\*/)\n+`)
			content = reEnd.ReplaceAllString(content, "${1}\n\n")
		}
	}

	content = strings.TrimRight(content, " \n\r\t")
	if content != "" {
		content += "\n"
	}

	content = frontmatter + content
	res.Modified = res.Modified || (content != originalContent)
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
	specificYearRegex := regexp.MustCompile(`(?i)(?:Copyright|SPDX-FileCopyrightText:)\s+([0-9]{4})(?:-[0-9]{4})?\s+` + quotedHolder)
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
		if len(match) > 2 {
			foundHolder := strings.TrimSpace(match[2])
			if !strings.Contains(strings.ToLower(foundHolder), strings.ToLower(targetHolder)) {
				return foundHolder
			}
		}
	}
	return ""
}

// EnforceFile reads a file, applies licensing, and writes it back if changed.
func EnforceFile(path string, currentYear int, holder string, targetLicense string, format string, acceptableLicenses ...string) (Result, error) {
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

	if ext == "" {
		base := filepath.Base(path)
		if base == "Dockerfile" {
			ext = "dockerfile"
		} else if base == "Makefile" {
			ext = "makefile"
		}
	}

	newContent, res := ProcessFileContent(content, ext, currentYear, holder, targetLicense, format, acceptableLicenses...)

	if res.Modified {
		err = os.WriteFile(path, []byte(newContent), 0644)
		if err != nil {
			return Result{}, err
		}
	}

	return res, nil
}
