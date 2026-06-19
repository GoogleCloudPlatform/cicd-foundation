/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/GoogleCloudPlatform/cicd-foundation/apps/workstations/preflight/tools/setup-workstation/internal/setup"
)

// parseFlags defines the CLI flags, evaluates environment variable fallbacks,
// and returns the populated Options struct alongside the needsSetup boolean.
func parseFlags() (setup.Options, bool) {
	var config, directory string
	var needsSetup, reset bool

	flag.BoolVar(&needsSetup, "needs-setup", false, "Check if setup is required and exit (0 if required, 1 if done)")
	flag.BoolVar(&needsSetup, "n", false, "Shorthand for --needs-setup")

	flag.BoolVar(&reset, "reset", false, "Force rerun setup ignoring previous config choices")
	flag.BoolVar(&reset, "r", false, "Shorthand for --reset")

	defaultConfig := os.Getenv("SETUP_CONFIG")
	if defaultConfig == "" {
		defaultConfig = "/google/etc/setup-workstation.yaml"
	}
	flag.StringVar(&config, "config", defaultConfig, "Path to the configuration YAML")
	flag.StringVar(&config, "c", defaultConfig, "Shorthand for --config")

	defaultDir := os.Getenv("SETUP_DIRECTORY")
	if defaultDir == "" {
		defaultDir = "/google/etc/setup-workstation.d"
	}
	flag.StringVar(&directory, "directory", defaultDir, "Path to the template directory")
	flag.StringVar(&directory, "d", defaultDir, "Shorthand for --directory")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Cloud Workstation Setup CLI\n\n")
		fmt.Fprintf(os.Stderr, "Usage:\n  setup-workstation [flags]\n\n")
		fmt.Fprintf(os.Stderr, "Flags:\n")
		fmt.Fprintf(os.Stderr, "  -c, --config string\n    \tPath to the configuration YAML (default %q)\n", defaultConfig)
		fmt.Fprintf(os.Stderr, "  -d, --directory string\n    \tPath to the template directory (default %q)\n", defaultDir)
		fmt.Fprintf(os.Stderr, "  -n, --needs-setup\n    \tCheck if setup is required and exit (0 if required, 1 if done)\n")
		fmt.Fprintf(os.Stderr, "  -r, --reset\n    \tForce rerun setup ignoring previous config choices\n")
	}

	flag.Parse()

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error getting home directory: %v\n", err)
		os.Exit(1)
	}

	opts := setup.Options{
		HomeDir:    homeDir,
		ConfigPath: config,
		SourceDir:  directory,
		ForceReset: reset,
	}

	return opts, needsSetup
}
