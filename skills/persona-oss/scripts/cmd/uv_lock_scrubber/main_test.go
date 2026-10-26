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

package main

import (
	"bytes"
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRunCLIAutoScrubAndIdempotentSecondPass(t *testing.T) {
	const sha = "42d35340cc5b9ba78e818ddbff0c5b1c2b779de448a340fd1b989f5fa8670e1b"
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{
			"urls": [{
				"filename": "certifi-2026.10.19-py3-none-any.whl",
				"url": "https://files.pythonhosted.org/packages/ef/01/9876543210/certifi-2026.10.19-py3-none-any.whl",
				"digests": {"sha256": %q}
			}]
		}`, sha)
	}))
	defer srv.Close()

	tmpDir := t.TempDir()
	lockPath := filepath.Join(tmpDir, "uv.lock")
	initial := fmt.Sprintf(`version = 1

[[package]]
name = "certifi"
version = "2026.10.19"
source = { registry = "https://mirror.example.com/simple/" }
wheels = [
    { url = "https://mirror.example.com/certifi/certifi-2026.10.19-py3-none-any.whl", hash = "sha256:%s" },
]
`, sha)

	if err := os.WriteFile(lockPath, []byte(initial), 0o644); err != nil {
		t.Fatalf("WriteFile failed: %v", err)
	}

	var out bytes.Buffer
	// First run in --check mode fails without modifying file.
	if err := run(context.Background(), srv.URL, true, []string{lockPath}, &out); err == nil {
		t.Fatalf("expected --check mode to return non-nil error on non-public URLs")
	}

	// Autofix run rewrites the lockfile and returns "files modified" per pre-commit convention.
	out.Reset()
	err := run(context.Background(), srv.URL, false, []string{lockPath}, &out)
	if err == nil || err.Error() != "files modified" {
		t.Fatalf("autofix run error = %v, want 'files modified'", err)
	}

	// Second run on scrubbed lockfile exits nil cleanly.
	out.Reset()
	if err := run(context.Background(), srv.URL, false, []string{lockPath}, &out); err != nil {
		t.Fatalf("second pass returned unexpected error: %v", err)
	}
	if !strings.Contains(out.String(), "PyPI") {
		t.Errorf("expected clean status message, got %q", out.String())
	}
}
