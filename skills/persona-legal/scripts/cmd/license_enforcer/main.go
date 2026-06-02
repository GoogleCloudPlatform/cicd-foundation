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

// Package main provides the entry point for the license_enforcer utility.
package main

import (
	"flag"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-legal/scripts/internal/i18n"
	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-legal/scripts/internal/licensing"
	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-legal/scripts/internal/locales"
)

const (
	concurrencyLimit = 20
)

var (
	holder        = flag.String("holder", "Google LLC", "Copyright holder name.")
	targetLicense = flag.String("license", "Apache-2.0", "SPDX license identifier to enforce.")
	exclude       = flag.String("exclude", "node_modules/ dist/ licenses/ check_licenses.py LICENSE COPYING NOTICE", "Space-separated list of strings to exclude.")
	filter        = flag.String("filter", `\.(ts|js|cjs|mjs|jsx|tsx|css|go|sh|bash|bats|py|desktop|yaml|yml|conf|list|html|md|xml|template|tmpl)$|^Dockerfile$`, "Regex to filter files.")
)

func main() {
	flag.Usage = func() {
		fmt.Println(i18n.T("usage_license_enforcer"))
	}
	flag.Parse()

	if err := run(*holder, *targetLicense, *exclude, *filter, flag.Args()); err != nil {
		if err.Error() != "files modified" {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
			os.Exit(1)
		}
		os.Exit(1)
	}
}

// run executes the license enforcement logic.
func run(holderName, licenseID, excludePaths, filterPat string, args []string) error {
	if err := i18n.Init("", "en", locales.Content); err != nil {
		return fmt.Errorf("failed to initialize i18n: %w", err)
	}

	excludeList := strings.Fields(excludePaths)
	filterRegex, err := regexp.Compile(filterPat)
	if err != nil {
		return fmt.Errorf("invalid filter regex: %w", err)
	}

	var paths []string
	currentYear := time.Now().Year()

	if len(args) == 0 {
		return nil
	}

	for _, arg := range args {
		info, err := os.Stat(arg)
		if err != nil {
			fmt.Println(i18n.TF("license_enforcer_error_stat", map[string]interface{}{"Path": arg, "Error": err}))
			continue
		}

		if !info.IsDir() {
			excluded := false
			for _, ex := range excludeList {
				if strings.Contains(arg, ex) {
					excluded = true
					break
				}
			}
			if !excluded && filterRegex.MatchString(arg) {
				paths = append(paths, arg)
			}
			continue
		}

		err = filepath.WalkDir(arg, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				for _, ex := range excludeList {
					if strings.Contains(path, ex) {
						return filepath.SkipDir
					}
				}
				if d.Name() == ".git" || d.Name() == "node_modules" {
					return filepath.SkipDir
				}
				return nil
			}

			if filterRegex.MatchString(path) {
				excluded := false
				for _, ex := range excludeList {
					if strings.Contains(path, ex) {
						excluded = true
						break
					}
				}
				if !excluded {
					paths = append(paths, path)
				}
			}
			return nil
		})
		if err != nil {
			fmt.Println(i18n.TF("license_enforcer_error_walk", map[string]interface{}{"Path": arg, "Error": err}))
		}
	}

	var wg sync.WaitGroup
	var mu sync.Mutex
	modifiedCount := 0
	sem := make(chan struct{}, concurrencyLimit)

	for _, p := range paths {
		wg.Add(1)
		go func(path string) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()

			res, err := licensing.EnforceFile(path, currentYear, holderName, licenseID)
			if err != nil {
				fmt.Fprintf(os.Stderr, "failed to process %s: %v\n", path, err)
				return
			}

			if res.Modified {
				mu.Lock()
				if res.LicenseAdded {
					fmt.Println(i18n.TF("license_enforcer_applying", map[string]interface{}{"Path": path, "License": licenseID}))
				} else if res.YearUpdated {
					fmt.Println(i18n.TF("license_enforcer_updating", map[string]interface{}{"Path": path}))
				} else {
					fmt.Println(i18n.TF("license_enforcer_fixing", map[string]interface{}{"Path": path}))
				}
				modifiedCount++
				mu.Unlock()
			}

			if res.DifferentHolder != "" {
				mu.Lock()
				fmt.Println(i18n.TF("license_enforcer_different_holder", map[string]interface{}{"Path": path, "Holder": res.DifferentHolder}))
				mu.Unlock()
			}
		}(p)
	}

	wg.Wait()

	if modifiedCount > 0 {
		fmt.Println(i18n.TF("license_enforcer_summary", map[string]interface{}{"Count": modifiedCount}))
		return fmt.Errorf("files modified")
	}

	fmt.Println(i18n.T("license_enforcer_success"))
	return nil
}
