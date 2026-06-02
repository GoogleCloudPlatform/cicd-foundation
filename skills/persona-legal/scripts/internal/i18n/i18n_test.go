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

package i18n

import (
	"embed"
	"io/fs"
	"testing"
)

//go:embed testdata/*.json
var testLocales embed.FS

func TestI18n(t *testing.T) {
	sub, err := fs.Sub(testLocales, "testdata")
	if err != nil {
		t.Fatalf("fs.Sub failed: %v", err)
	}
	err = Init("en", "en", sub)
	if err != nil {
		t.Fatalf("Init failed: %v", err)
	}

	t.Run("simple_translation", func(t *testing.T) {
		got := T("test_simple")
		want := "Simple Translation"
		if got != want {
			t.Errorf("T() = %q, want %q", got, want)
		}
	})

	t.Run("template_translation", func(t *testing.T) {
		got := TF("test_template", map[string]interface{}{"Name": "World"})
		want := "Hello World!"
		if got != want {
			t.Errorf("TF() = %q, want %q", got, want)
		}
	})

	t.Run("missing_id", func(t *testing.T) {
		got := T("non_existent")
		want := "non_existent"
		if got != want {
			t.Errorf("T() for missing ID = %q, want %q", got, want)
		}
	})
}
