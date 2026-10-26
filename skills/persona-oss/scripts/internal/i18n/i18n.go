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

// Package i18n provides internationalization and localization support for persona-oss scripts.
package i18n

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"

	goi18n "github.com/nicksnyder/go-i18n/v2/i18n"
	"golang.org/x/text/language"
)

var (
	bundle    *goi18n.Bundle
	localizer *goi18n.Localizer
)

// Init loads all JSON message catalogs from localesFS and configures the active localizer.
func Init(lang, defaultLang string, localesFS fs.FS) error {
	bundle = goi18n.NewBundle(language.MustParse(defaultLang))
	bundle.RegisterUnmarshalFunc("json", json.Unmarshal)

	files, err := fs.ReadDir(localesFS, ".")
	if err != nil {
		return fmt.Errorf("failed to read locales from fs: %w", err)
	}

	for _, f := range files {
		if filepath.Ext(f.Name()) != ".json" {
			continue
		}
		data, err := fs.ReadFile(localesFS, f.Name())
		if err != nil {
			return fmt.Errorf("failed to read locale file %s: %w", f.Name(), err)
		}
		if _, err := bundle.ParseMessageFileBytes(data, f.Name()); err != nil {
			return fmt.Errorf("failed to parse locale file %s: %w", f.Name(), err)
		}
	}

	if lang == "" {
		lang = os.Getenv("LANG")
	}

	localizer = goi18n.NewLocalizer(bundle, lang, defaultLang)
	return nil
}

// T translates a message ID with no template arguments.
func T(id string) string {
	if localizer == nil {
		return id
	}
	msg, err := localizer.Localize(&goi18n.LocalizeConfig{MessageID: id})
	if err != nil {
		return id
	}
	return msg
}

// TF translates a message ID using the supplied template data map.
func TF(id string, data map[string]any) string {
	if localizer == nil {
		return id
	}
	msg, err := localizer.Localize(&goi18n.LocalizeConfig{
		MessageID:    id,
		TemplateData: data,
	})
	if err != nil {
		return id
	}
	return msg
}
