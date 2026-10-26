<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Legal Enforcer Internationalization (`internal/i18n`)

## Overview

Provides internationalization (i18n) bundle initialization and message
localization helpers for the `license_enforcer` CLI tool.

## Interface

- `Init(lang, defaultLang string, localesFS fs.FS) error`: Initializes the
  package-level `i18n.Bundle` and `i18n.Localizer` using JSON locale files
  from the root of `localesFS`.
- `T(id string) string`: Translates a message ID using the package-level
  localizer, returning `id` on failure or if uninitialized.
- `TF(id string, data map[string]interface{}) string`: Translates a message ID
  with template data using the package-level localizer, returning `id` on
  failure or if uninitialized.

## Invariants

- `defaultLang` passed to `Init` must be valid according to
  `golang.org/x/text/language.MustParse` or `Init` will panic.
- Only files with a `.json` extension in the root directory (`"."`) of
  `localesFS` are loaded into the bundle.
- If `lang` is empty in `Init`, language resolution falls back to the `LANG`
  environment variable and then `defaultLang`.
- `T` and `TF` always return the untranslated `id` string if `localizer` is
  `nil` or if localization fails.

## Side Effects

- `Init` mutates unsynchronized package-level globals `bundle`
  (`*i18n.Bundle`) and `localizer` (`*i18n.Localizer`).
- `Init` reads directory entries and `.json` files from the provided `fs.FS`.
- `Init` reads the process environment variable `LANG` via `os.Getenv("LANG")`
  when `lang` is empty.
- `Init` panics via `language.MustParse` if `defaultLang` is not a valid
  language tag.
