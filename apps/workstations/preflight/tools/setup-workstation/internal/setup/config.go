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

package setup

import (
	"bytes"
	"fmt"
	"os"
	"strings"

	"gopkg.in/yaml.v3"
)

// Config represents the setup-workstation blueprint schema.
type Config struct {
	Inputs      []Input          `yaml:"inputs"`
	Permissions []PermissionRule `yaml:"permissions"`
}

// PermissionRule defines how file permissions should be enforced.
type PermissionRule struct {
	Path string `yaml:"path"`
	Mode string `yaml:"mode"`
}

// Input represents a single configuration field requested from the user.
type Input struct {
	ID          string `yaml:"id"`
	Prompt      string `yaml:"prompt"`
	Description string `yaml:"description"`
	Default     string `yaml:"default"`
	DefaultEnv  string `yaml:"default_env"`
	Required    bool   `yaml:"required"`
	Validation  struct {
		Type    string   `yaml:"type"`
		Options []string `yaml:"options"`
	} `yaml:"validation"`
}

// loadConfig reads and parses the YAML config file.
func loadConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var cfg Config
	dec := yaml.NewDecoder(bytes.NewReader(data))
	dec.KnownFields(true)
	if err := dec.Decode(&cfg); err != nil {
		return nil, fmt.Errorf("parsing yaml: %w", err)
	}

	return &cfg, nil
}

// resolveDefaults maps inputs to environment variables if available.
// environ is a function returning standard environment strings (e.g. "KEY=VALUE").
func resolveDefaults(cfg *Config, environ func() []string) map[string]interface{} {
	envMap := make(map[string]string)
	for _, env := range environ() {
		parts := strings.SplitN(env, "=", 2)
		if len(parts) == 2 {
			envMap[parts[0]] = parts[1]
		}
	}

	answers := make(map[string]interface{})
	for _, input := range cfg.Inputs {
		if input.DefaultEnv != "" {
			if val, ok := envMap[input.DefaultEnv]; ok && val != "" {
				answers[input.ID] = val
			}
		}
	}
	return answers
}
