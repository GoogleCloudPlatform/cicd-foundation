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
	"testing"
)

func TestGitAuthorName(t *testing.T) {
	name, err := GitAuthorName()
	if err != nil {
		t.Logf("GitAuthorName returned error (expected if git config is unset): %v", err)
		return
	}
	t.Logf("GitAuthorName returned: %q", name)
}

func TestResolveDefaultHolder(t *testing.T) {
	name, err := ResolveDefaultHolder()
	if err != nil {
		t.Logf("ResolveDefaultHolder returned error (expected if git config is unset): %v", err)
	} else if name == "" {
		t.Errorf("ResolveDefaultHolder returned empty name with nil error")
	}
}
