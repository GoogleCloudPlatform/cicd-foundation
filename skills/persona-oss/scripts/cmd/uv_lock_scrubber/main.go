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

// Package main provides the uv_lock_scrubber pre-commit CLI for rewriting
// non-public package mirror URLs in uv.lock files back to canonical PyPI URLs.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"

	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-oss/scripts/internal/i18n"
	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-oss/scripts/internal/locales"
	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-oss/scripts/internal/uvlock"
)

var (
	apiBase   = flag.String("api-base", uvlock.DefaultPyPIAPIBase, "Upstream PyPI JSON API base URL")
	checkOnly = flag.Bool("check", false, "Verify lockfiles contain only public PyPI URLs without modifying files")
)

var skipDirs = map[string]bool{
	// keep-sorted start
	".git":         true,
	".terraform":   true,
	".venv":        true,
	"build":        true,
	"dist":         true,
	"node_modules": true,
	"tmp":          true,
	// keep-sorted end
}

func main() {
	if err := i18n.Init("", "en", locales.Content); err != nil {
		fmt.Fprintf(os.Stderr, "failed to initialize i18n: %v\n", err)
		os.Exit(1)
	}

	flag.Usage = func() {
		fmt.Println(i18n.T("usage_uv_lock_scrubber"))
	}
	flag.Parse()

	if err := run(context.Background(), *apiBase, *checkOnly, flag.Args(), os.Stdout); err != nil {
		if err.Error() != "files modified" {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
		}
		os.Exit(1)
	}
}

func run(ctx context.Context, apiBase string, checkOnly bool, args []string, stdout io.Writer) error {
	if err := i18n.Init("", "en", locales.Content); err != nil {
		return fmt.Errorf("failed to initialize i18n: %w", err)
	}

	targets, err := collectTargets(args)
	if err != nil {
		return err
	}
	if len(targets) == 0 {
		return nil
	}

	scrubber := &uvlock.Scrubber{
		Resolver:  uvlock.NewHTTPPyPIResolver(apiBase, nil),
		CheckOnly: checkOnly,
	}

	modifiedFiles := 0
	taintedFiles := 0

	for _, target := range targets {
		res, err := scrubber.ProcessFile(ctx, target)
		if err != nil {
			return err
		}
		if res.Replacements > 0 {
			if checkOnly {
				taintedFiles++
				fmt.Fprintln(stdout, i18n.TF("uv_lock_scrubber_needs_scrub", map[string]any{
					"Path":  target,
					"Count": res.Replacements,
				}))
			} else if res.Modified {
				modifiedFiles++
				fmt.Fprintln(stdout, i18n.TF("uv_lock_scrubber_rewritten", map[string]any{
					"Path":  target,
					"Count": res.Replacements,
				}))
			}
		}
	}

	if checkOnly && taintedFiles > 0 {
		return errors.New(i18n.TF("error_check_mode_failed", map[string]any{
			"Count": taintedFiles,
		}))
	}

	if modifiedFiles > 0 {
		fmt.Fprintln(stdout, i18n.TF("uv_lock_scrubber_summary", map[string]any{
			"Count": modifiedFiles,
		}))
		return errors.New("files modified")
	}

	fmt.Fprintln(stdout, i18n.T("uv_lock_scrubber_clean"))
	return nil
}

func collectTargets(args []string) ([]string, error) {
	if len(args) > 0 {
		var targets []string
		for _, arg := range args {
			if filepath.Base(arg) != "uv.lock" {
				continue
			}
			targets = append(targets, filepath.Clean(arg))
		}
		return targets, nil
	}

	cwd, err := os.Getwd()
	if err != nil {
		return nil, fmt.Errorf("failed to determine working directory: %w", err)
	}

	var targets []string
	walkErr := filepath.WalkDir(cwd, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			if skipDirs[d.Name()] {
				return filepath.SkipDir
			}
			return nil
		}
		if d.Name() == "uv.lock" {
			targets = append(targets, p)
		}
		return nil
	})
	if walkErr != nil {
		return nil, fmt.Errorf("failed to walk directory: %w", walkErr)
	}
	return targets, nil
}
