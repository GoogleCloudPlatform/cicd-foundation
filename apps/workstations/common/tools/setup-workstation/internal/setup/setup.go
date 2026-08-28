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

// Package setup orchestrates the workstation configuration and template hydration.
package setup

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/charmbracelet/huh"
	"gopkg.in/yaml.v3"
)

const (
	doneFileName          = "setup-workstation-done"
	chezmoiConfigFileName = "chezmoi.yaml"
)

// Options defines the runtime configuration.
type Options struct {
	HomeDir    string
	ConfigPath string
	SourceDir  string
	ForceReset bool
	FormRunner func(*huh.Form) error
	Stdout     io.Writer
	Stderr     io.Writer
}

// Run orchestrates the workspace setup process.
func Run(ctx context.Context, opts Options, sh Shell) error {
	if sh == nil {
		sh = &OSShell{}
	}
	if opts.Stdout == nil {
		opts.Stdout = os.Stdout
	}
	if opts.Stderr == nil {
		opts.Stderr = os.Stderr
	}

	if err := CheckRunnable(opts); err != nil {
		return err
	}

	cfg, answers, missingOptionals, err := collectAnswers(opts)
	if err != nil {
		return err
	}

	return applyState(ctx, opts, sh, cfg, answers, missingOptionals)
}

// collectAnswers parses configuration and collects user responses (interactive or env).
func collectAnswers(opts Options) (*Config, map[string]interface{}, []string, error) {
	cfg, err := loadConfig(opts.ConfigPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil, nil, fmt.Errorf("setup config not found at %s", opts.ConfigPath)
		}
		return nil, nil, nil, fmt.Errorf("failed to load config: %w", err)
	}

	answers := resolveDefaults(cfg, os.Environ)
	missingOptionals := []string{}

	var previousAnswers map[string]string
	if !opts.ForceReset {
		var err error
		previousAnswers, err = loadPreviousAnswers(opts.HomeDir)
		if err != nil {
			fmt.Fprintf(opts.Stderr, "Warning: failed to load previous configurations: %v\n", err)
		}
	}

	if err := buildAndRunForm(cfg, answers, previousAnswers, opts.FormRunner, &missingOptionals); err != nil {
		return nil, nil, nil, fmt.Errorf("form execution failed: %w", err)
	}

	// Ensure all configuration inputs exist in the map to satisfy
	// Chezmoi's strict text/template `missingkey=error` execution behavior.
	for _, input := range cfg.Inputs {
		if _, exists := answers[input.ID]; !exists {
			answers[input.ID] = ""
		}
	}

	return cfg, answers, missingOptionals, nil
}

// applyState hydrates templates and deploys them to home using Chezmoi.
func applyState(ctx context.Context, opts Options, sh Shell, cfg *Config, answers map[string]interface{}, missingOptionals []string) error {
	if err := writeChezmoiData(opts.HomeDir, answers, missingOptionals, opts.Stderr); err != nil {
		return fmt.Errorf("failed to write chezmoi data: %w", err)
	}

	if info, err := os.Stat(opts.SourceDir); err != nil || !info.IsDir() {
		return fmt.Errorf("template source directory does not exist or is invalid: %s", opts.SourceDir)
	}

	tmpSourceDir, err := prepareSourceDir(opts.SourceDir, cfg.Permissions)
	if err != nil {
		return fmt.Errorf("failed to prepare source directory: %w", err)
	}
	defer os.RemoveAll(tmpSourceDir)

	fmt.Fprintln(opts.Stdout, "\nApplying configuration...")
	err = sh.Run(ctx, "chezmoi", "apply", "--source", tmpSourceDir, "--force")
	if err != nil {
		return fmt.Errorf("chezmoi apply failed: %w", err)
	}

	// Query Chezmoi for the absolute paths of all managed files it just applied.
	// We ignore errors here because setup succeeded, and showing the files list is non-critical.
	managedOut, err := sh.Output(ctx, "chezmoi", "managed", "-i", "files", "--source", tmpSourceDir, "--path-style", "absolute")
	if err == nil && len(managedOut) > 0 {
		fmt.Fprintf(opts.Stdout, "\nGenerated Files:\n")
		files := strings.Split(strings.TrimSpace(string(managedOut)), "\n")
		for _, f := range files {
			if f != "" {
				fmt.Fprintf(opts.Stdout, "  - %s\n", f)
			}
		}
	}

	if err := markDone(opts.HomeDir); err != nil {
		return fmt.Errorf("failed to mark setup as done: %w", err)
	}

	fmt.Fprintln(opts.Stdout, "\nWorkspace setup complete!")
	return nil
}

// getStateDir returns the workstation state directory, respecting XDG_STATE_HOME.
func getStateDir(homeDir string) string {
	if xdg := os.Getenv("XDG_STATE_HOME"); xdg != "" {
		return xdg
	}
	return filepath.Join(homeDir, ".local", "state")
}

// markDone touches the state file to prevent setup from running again.
func markDone(homeDir string) error {
	stateDir := getStateDir(homeDir)
	if err := os.MkdirAll(stateDir, 0755); err != nil {
		return fmt.Errorf("creating state dir: %w", err)
	}

	doneFile := filepath.Join(stateDir, doneFileName)
	if err := os.WriteFile(doneFile, []byte("done\n"), 0644); err != nil {
		return fmt.Errorf("writing %s file: %w", doneFileName, err)
	}

	return nil
}

// IsDone checks if the setup has already been completed.
func IsDone(homeDir string) bool {
	doneFile := filepath.Join(getStateDir(homeDir), doneFileName)
	_, err := os.Stat(doneFile)
	return err == nil
}

// CheckRunnable validates that the configuration file exists and the template
// directory is not empty.
func CheckRunnable(opts Options) error {
	if _, err := os.Stat(opts.ConfigPath); err != nil {
		if os.IsNotExist(err) {
			return fmt.Errorf("config file does not exist: %s", opts.ConfigPath)
		}
		return fmt.Errorf("failed to stat config file: %w", err)
	}

	info, err := os.Stat(opts.SourceDir)
	if err != nil {
		if os.IsNotExist(err) {
			return fmt.Errorf("template source directory does not exist: %s", opts.SourceDir)
		}
		return fmt.Errorf("failed to stat template source directory: %w", err)
	}
	if !info.IsDir() {
		return fmt.Errorf("template source path is not a directory: %s", opts.SourceDir)
	}

	files, err := os.ReadDir(opts.SourceDir)
	if err != nil {
		return fmt.Errorf("reading template source directory: %w", err)
	}
	if len(files) == 0 {
		return fmt.Errorf("template source directory is empty: %s", opts.SourceDir)
	}

	return nil
}

// loadPreviousAnswers reads and parses the data block of ~/.config/chezmoi/chezmoi.yaml
func loadPreviousAnswers(homeDir string) (map[string]string, error) {
	path := filepath.Join(homeDir, ".config", "chezmoi", chezmoiConfigFileName)
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil // Silently ignore if no previous configuration exists
		}
		return nil, err
	}

	var parsed struct {
		Data map[string]string `yaml:"data"`
	}
	if err := yaml.Unmarshal(data, &parsed); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", chezmoiConfigFileName, err)
	}

	return parsed.Data, nil
}
