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

package i18n_test

import (
	"encoding/json"
	"io/fs"
	"sort"
	"strings"
	"testing"

	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-oss/scripts/internal/i18n"
	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-oss/scripts/internal/locales"
)

type localeEntry struct {
	ID          string `json:"id"`
	Translation string `json:"translation"`
}

func TestAllUNLocalesLoadAndSorted(t *testing.T) {
	supported := []string{"ar", "en", "es", "fr", "ru", "zh"}
	for _, lang := range supported {
		if err := i18n.Init(lang, "en", locales.Content); err != nil {
			t.Fatalf("Init(%q) failed: %v", lang, err)
		}
		got := i18n.T("uv_lock_scrubber_clean")
		if got == "" || got == "uv_lock_scrubber_clean" {
			t.Errorf("lang %q returned untranslated key %q", lang, got)
		}

		raw, err := fs.ReadFile(locales.Content, lang+".json")
		if err != nil {
			t.Fatalf("failed to read %s.json: %v", lang, err)
		}
		var entries []localeEntry
		if err := json.Unmarshal(raw, &entries); err != nil {
			t.Fatalf("failed to unmarshal %s.json: %v", lang, err)
		}

		ids := make([]string, len(entries))
		for idx, entry := range entries {
			ids[idx] = entry.ID
			if strings.HasPrefix(entry.ID, "error_") && strings.HasSuffix(entry.Translation, ".") {
				t.Errorf("%s.json key %q ends with trailing period: %q", lang, entry.ID, entry.Translation)
			}
		}
		if !sort.StringsAreSorted(ids) {
			t.Errorf("%s.json IDs are not sorted alphabetically: %v", lang, ids)
		}
	}
}
