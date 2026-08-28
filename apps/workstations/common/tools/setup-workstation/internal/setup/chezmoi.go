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
	"io"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

// writeChezmoiData persists the answers.
func writeChezmoiData(homeDir string, answers map[string]interface{}, missingOptionals []string, warnWriter io.Writer) error {
	chezmoiConfigDir := filepath.Join(homeDir, ".config", "chezmoi")
	if err := os.MkdirAll(chezmoiConfigDir, 0755); err != nil {
		return fmt.Errorf("creating config dir: %w", err)
	}

	chezmoiDataPath := filepath.Join(chezmoiConfigDir, chezmoiConfigFileName)

	configWrapper := map[string]interface{}{
		"data": answers,
	}
	outData, err := yaml.Marshal(configWrapper)
	if err != nil {
		return fmt.Errorf("marshaling yaml: %w", err)
	}

	// 0600 prevents other users from reading sensitive secrets
	if err := os.WriteFile(chezmoiDataPath, outData, 0600); err != nil {
		return fmt.Errorf("writing %s: %w", chezmoiConfigFileName, err)
	}

	if warnWriter != nil {
		for _, missing := range missingOptionals {
			fmt.Fprintf(warnWriter, "Warning: Optional input '%s' was omitted. Related configuration blocks may be skipped.\n", missing)
		}
	}

	return nil
}

// Chezmoi translation permission mode constants.
const (
	// modePrivate defines read/write access for the owner only (commonly used for keys, tokens, or credentials).
	modePrivate = "0600"
	// modeExecutable defines read/execute access for everyone (commonly used for system-wide scripts or binaries).
	modeExecutable = "0755"
	// modePrivateExecutableOwner defines read/write/execute access for the owner only (commonly used for private scripts).
	modePrivateExecutableOwner = "0700"
	// modePrivateExecutableOwnerRead defines read/execute access for the owner only.
	modePrivateExecutableOwnerRead = "0500"
	// modeReadOnly defines read-only access for everyone (commonly used for static configuration defaults).
	modeReadOnly = "0444"
)

// translatePath transforms a repository path into its Chezmoi-compatible destination format,
// translating hidden dots, mapping custom permissions to prefix modifiers, and appending .tmpl.
func translatePath(relPath string, isDir bool, permMap map[string]string) string {
	origParts := strings.Split(relPath, string(filepath.Separator))
	destParts := make([]string, len(origParts))

	for i, part := range origParts {
		newPart := part
		// Map dotfiles
		if strings.HasPrefix(part, ".") {
			newPart = "dot_" + part[1:]
		}

		// Map permission prefixes
		origPathUpToI := filepath.Join(origParts[:i+1]...)
		if mode, ok := permMap[origPathUpToI]; ok {
			switch mode {
			case modePrivate:
				newPart = "private_" + newPart
			case modeExecutable:
				newPart = "executable_" + newPart
			case modePrivateExecutableOwner, modePrivateExecutableOwnerRead:
				newPart = "private_executable_" + newPart
			case modeReadOnly:
				newPart = "readonly_" + newPart
			}
		}

		// Append template suffix to filenames
		if i == len(origParts)-1 && !isDir {
			if !strings.HasSuffix(newPart, ".tmpl") {
				newPart = newPart + ".tmpl"
			}
		}
		destParts[i] = newPart
	}

	return filepath.Join(destParts...)
}

// prepareSourceDir creates a temporary directory and copies the sourceDir into it,
// translating base names that start with "." to "dot_" and enforcing permissions.
func prepareSourceDir(sourceDir string, permissions []PermissionRule) (string, error) {
	tmpSource, err := os.MkdirTemp("", "setup-workstation-source-*")
	if err != nil {
		return "", fmt.Errorf("failed to create temp source dir: %w", err)
	}

	permMap := make(map[string]string)
	for _, p := range permissions {
		permMap[filepath.Clean(p.Path)] = p.Mode
	}

	err = filepath.WalkDir(sourceDir, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel(sourceDir, path)
		if err != nil {
			return err
		}
		if relPath == "." {
			return nil
		}

		translatedRel := translatePath(relPath, entry.IsDir(), permMap)
		destPath := filepath.Join(tmpSource, translatedRel)

		if entry.IsDir() {
			info, err := entry.Info()
			if err != nil {
				return err
			}
			return os.MkdirAll(destPath, info.Mode())
		}

		info, err := entry.Info()
		if err != nil {
			return err
		}

		return copyFile(path, destPath, info.Mode())
	})

	if err != nil {
		os.RemoveAll(tmpSource)
		return "", err
	}

	return tmpSource, nil
}

// copyFile copies a file from srcPath to destPath with the given mode.
func copyFile(srcPath, destPath string, mode os.FileMode) error {
	srcFile, err := os.Open(srcPath)
	if err != nil {
		return err
	}
	defer srcFile.Close()

	destFile, err := os.OpenFile(destPath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, mode)
	if err != nil {
		return err
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, srcFile)
	return err
}
