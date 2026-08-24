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

// Package main implements a markdown link checker tool.
package main

import (
	"flag"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-swe/scripts/internal/linkchecker"
)

// excludeDirs defines directories to skip during scanning.
var excludeDirs = map[string]bool{
	".git":         true,
	".terraform":   true,
	".venv":        true,
	"node_modules": true,
	"build":        true,
	"dist":         true,
	"tmp":          true,
}

func findRepoRoot() (string, error) {
	cwd, err := os.Getwd()
	if err != nil {
		return "", err
	}
	dir := cwd
	for {
		if _, err := os.Stat(filepath.Join(dir, ".git")); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	return cwd, nil // Fallback to CWD
}

func main() {
	// Support standard -- flag separator
	flag.Parse()

	repoRoot, err := findRepoRoot()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error finding repo root: %v\n", err)
		os.Exit(1)
	}

	var filesToCheck []string

	if len(flag.Args()) > 0 {
		// Use files passed as arguments
		cwd, err := os.Getwd()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error getting CWD: %v\n", err)
			os.Exit(1)
		}
		for _, arg := range flag.Args() {
			absPath := arg
			if !filepath.IsAbs(arg) {
				absPath = filepath.Join(cwd, arg)
			}

			// Clean the path to resolve relative segments like ..
			absPath = filepath.Clean(absPath)

			if !strings.HasSuffix(absPath, ".md") {
				continue
			}
			if _, err := os.Stat(absPath); err == nil {
				filesToCheck = append(filesToCheck, absPath)
			} else {
				fmt.Fprintf(os.Stderr, "Warning: file not found: %s\n", arg)
			}
		}
		fmt.Printf("Checking %d specified file(s).\n", len(filesToCheck))
	} else {
		// Fallback to walking the repository
		fmt.Printf("Scanning repository root: %s\n", repoRoot)
		err = filepath.WalkDir(repoRoot, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				if excludeDirs[d.Name()] {
					return filepath.SkipDir
				}
				return nil
			}
			if strings.HasSuffix(d.Name(), ".md") {
				filesToCheck = append(filesToCheck, path)
			}
			return nil
		})
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error walking directory: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Found %d markdown files to check.\n", len(filesToCheck))
	}

	if len(filesToCheck) == 0 {
		fmt.Println("No markdown files to check.")
		os.Exit(0)
	}

	// Concurrency setup
	var wg sync.WaitGroup
	resultsChan := make(chan linkchecker.FileResult, len(filesToCheck))
	sem := make(chan struct{}, 50) // Limit concurrency to 50 active files

	for _, path := range filesToCheck {
		wg.Add(1)
		go func(p string) {
			defer wg.Done()
			sem <- struct{}{}        // Acquire semaphore
			defer func() { <-sem }() // Release semaphore

			broken, err := linkchecker.CheckFile(p, repoRoot)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error checking file %s: %v\n", p, err)
				return
			}
			if len(broken) > 0 {
				resultsChan <- linkchecker.FileResult{
					FilePath:    p,
					BrokenLinks: broken,
				}
			}
		}(path)
	}

	// Close channel when all workers are done
	go func() {
		wg.Wait()
		close(resultsChan)
	}()

	totalBroken := 0
	filesWithBroken := 0

	for result := range resultsChan {
		filesWithBroken++
		relPath, err := filepath.Rel(repoRoot, result.FilePath)
		if err != nil {
			relPath = result.FilePath
		}
		fmt.Printf("\n❌ %s:\n", relPath)
		for _, bl := range result.BrokenLinks {
			totalBroken++
			relResolved, err := filepath.Rel(repoRoot, bl.ResolvedPath)
			if err != nil {
				relResolved = bl.ResolvedPath
			}
			fmt.Printf("  Line %d: Broken link '%s' (Resolved to: %s)\n", bl.LineNum, bl.Link, relResolved)
		}
	}

	fmt.Println("\n======================================")
	if totalBroken == 0 {
		fmt.Println(" 🎉 No broken relative links found!")
		os.Exit(0)
	} else {
		fmt.Printf(" ⚠️ Found %d broken link(s) across %d file(s).\n", totalBroken, filesWithBroken)
		os.Exit(1)
	}
}
