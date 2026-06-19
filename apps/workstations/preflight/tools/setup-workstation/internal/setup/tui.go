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
	"fmt"

	"github.com/charmbracelet/huh"
)

// determineValue returns the default suggestion value (either previous input or schema default).
func determineValue(inputID string, defaultVal string, previousAnswers map[string]string) *string {
	ptr := new(string)
	if prevVal, ok := previousAnswers[inputID]; ok {
		*ptr = prevVal
	} else {
		*ptr = defaultVal
	}
	return ptr
}

// formatDescription appends "(Optional)" if the input is not required.
func formatDescription(desc string, required bool) string {
	if required {
		return desc
	}
	if desc != "" {
		return desc + " (Optional)"
	}
	return "(Optional)"
}

// createField maps schema inputs to huh.Field components.
func createField(input Input, valPtr *string) huh.Field {
	desc := formatDescription(input.Description, input.Required)

	if input.Validation.Type == "enum" && len(input.Validation.Options) > 0 {
		opts := make([]huh.Option[string], len(input.Validation.Options))
		for i, o := range input.Validation.Options {
			opts[i] = huh.NewOption(o, o)
		}

		return huh.NewSelect[string]().
			Title(input.Prompt).
			Description(desc).
			Options(opts...).
			Value(valPtr)
	}

	inputField := huh.NewInput().
		Title(input.Prompt).
		Description(desc).
		Value(valPtr)

	if input.Required {
		inputField.Validate(func(s string) error {
			if s == "" {
				return fmt.Errorf("this field is required")
			}
			return nil
		})
	}
	return inputField
}

// buildAndRunForm handles the interactive questionnaire.
func buildAndRunForm(cfg *Config, answers map[string]interface{}, previousAnswers map[string]string, runner func(*huh.Form) error, missingOptionals *[]string) error {
	var fields []huh.Field
	fieldIDMap := make(map[string]*string)

	for _, input := range cfg.Inputs {
		if _, ok := answers[input.ID]; ok {
			continue // Already resolved via environment variables
		}

		valPtr := determineValue(input.ID, input.Default, previousAnswers)
		fieldIDMap[input.ID] = valPtr

		fields = append(fields, createField(input, valPtr))
	}

	// Only run the form if there are fields to collect
	if len(fields) == 0 {
		return nil
	}

	if runner == nil {
		runner = func(f *huh.Form) error { return f.Run() }
	}

	form := huh.NewForm(huh.NewGroup(fields...))
	if err := runner(form); err != nil {
		return err
	}

	// Map collected values to answers map
	for _, input := range cfg.Inputs {
		if ptr, ok := fieldIDMap[input.ID]; ok {
			val := *ptr
			answers[input.ID] = val
			if val == "" && !input.Required {
				*missingOptionals = append(*missingOptionals, input.ID)
			}
		}
	}

	return nil
}
