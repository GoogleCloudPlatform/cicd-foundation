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
	"fmt"
	"os/exec"
	"strings"
)

// GitAuthorName retrieves the author name from git config (user.name).
func GitAuthorName() (string, error) {
	cmd := exec.Command("git", "config", "user.name")
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

// ResolveDefaultHolder resolves the default copyright holder from git config user.name.
// Returns an error if git config user.name is empty or fails.
func ResolveDefaultHolder() (string, error) {
	name, err := GitAuthorName()
	if err != nil || name == "" {
		return "", fmt.Errorf("git author name not configured in 'git config user.name'")
	}
	return name, nil
}
