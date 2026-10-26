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

package uvlock_test

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"

	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-oss/scripts/internal/i18n"
	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-oss/scripts/internal/locales"
	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-oss/scripts/internal/uvlock"
)

const (
	sdistSHA = "035c1e85572b141bf1c3a3eff0e33a8eb74917522f2559075ff8d2fea780a1ae"
	wheelSHA = "42d35340cc5b9ba78e818ddbff0c5b1c2b779de448a340fd1b989f5fa8670e1b"
)

const samplePrivateLock = `version = 1
revision = 3
requires-python = ">=3.11"

[[package]]
name = "certifi"
version = "2026.10.19"
source = { registry = "https://mirror.example.com/python/simple/" }
sdist = { url = "https://mirror.example.com/python/certifi/certifi-2026.10.19.tar.gz", hash = "sha256:035c1e85572b141bf1c3a3eff0e33a8eb74917522f2559075ff8d2fea780a1ae" }
wheels = [
    { url = "https://mirror.example.com/python/certifi/certifi-2026.10.19-py3-none-any.whl", hash = "sha256:42d35340cc5b9ba78e818ddbff0c5b1c2b779de448a340fd1b989f5fa8670e1b" },
]

[[package]]
name = "demo-app"
version = "0.1.0"
source = { virtual = "." }
dependencies = [
    { name = "certifi" },
]
`

const sampleCanonicalLock = `version = 1
revision = 3
requires-python = ">=3.11"

[[package]]
name = "certifi"
version = "2026.10.19"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/ab/cd/0123456789/certifi-2026.10.19.tar.gz", hash = "sha256:035c1e85572b141bf1c3a3eff0e33a8eb74917522f2559075ff8d2fea780a1ae" }
wheels = [
    { url = "https://files.pythonhosted.org/packages/ef/01/9876543210/certifi-2026.10.19-py3-none-any.whl", hash = "sha256:42d35340cc5b9ba78e818ddbff0c5b1c2b779de448a340fd1b989f5fa8670e1b" },
]

[[package]]
name = "demo-app"
version = "0.1.0"
source = { virtual = "." }
dependencies = [
    { name = "certifi" },
]
`

func initTestI18n(t *testing.T) {
	t.Helper()
	if err := i18n.Init("en", "en", locales.Content); err != nil {
		t.Fatalf("failed to initialize i18n: %v", err)
	}
}

func TestScrubberNoOpOnCanonicalLockfileWithoutNetwork(t *testing.T) {
	initTestI18n(t)

	// Nil resolver proves zero network lookups occur when lockfile is already clean.
	scrubber := &uvlock.Scrubber{Resolver: nil}
	out, count, err := scrubber.ProcessBytes(context.Background(), []byte(sampleCanonicalLock))
	if err != nil {
		t.Fatalf("ProcessBytes returned unexpected error: %v", err)
	}
	if count != 0 {
		t.Errorf("count = %d, want 0", count)
	}
	if string(out) != sampleCanonicalLock {
		t.Errorf("output differed from canonical input")
	}
}

func TestScrubberRewritesAndCachesPyPIMetadata(t *testing.T) {
	initTestI18n(t)

	var hits atomic.Int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hits.Add(1)
		if r.URL.Path != "/certifi/2026.10.19/json" {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{
			"urls": [
				{
					"filename": "certifi-2026.10.19.tar.gz",
					"url": "https://files.pythonhosted.org/packages/ab/cd/0123456789/certifi-2026.10.19.tar.gz",
					"digests": {"sha256": %q}
				},
				{
					"filename": "certifi-2026.10.19-py3-none-any.whl",
					"url": "https://files.pythonhosted.org/packages/ef/01/9876543210/certifi-2026.10.19-py3-none-any.whl",
					"digests": {"sha256": %q}
				}
			]
		}`, sdistSHA, wheelSHA)
	}))
	defer srv.Close()

	resolver := uvlock.NewHTTPPyPIResolver(srv.URL, srv.Client())
	scrubber := &uvlock.Scrubber{Resolver: resolver}

	tmpDir := t.TempDir()
	firstPath := filepath.Join(tmpDir, "first-uv.lock")
	secondPath := filepath.Join(tmpDir, "second-uv.lock")
	if err := os.WriteFile(firstPath, []byte(samplePrivateLock), 0o644); err != nil {
		t.Fatalf("WriteFile first failed: %v", err)
	}
	if err := os.WriteFile(secondPath, []byte(samplePrivateLock), 0o644); err != nil {
		t.Fatalf("WriteFile second failed: %v", err)
	}

	res1, err := scrubber.ProcessFile(context.Background(), firstPath)
	if err != nil {
		t.Fatalf("ProcessFile(first) failed: %v", err)
	}
	if !res1.Modified || res1.Replacements != 3 {
		t.Errorf("res1 = %+v, want Modified=true Replacements=3", res1)
	}

	res2, err := scrubber.ProcessFile(context.Background(), secondPath)
	if err != nil {
		t.Fatalf("ProcessFile(second) failed: %v", err)
	}
	if !res2.Modified || res2.Replacements != 3 {
		t.Errorf("res2 = %+v, want Modified=true Replacements=3", res2)
	}

	if gotHits := hits.Load(); gotHits != 1 {
		t.Errorf("HTTP API hits = %d, want 1 cached request", gotHits)
	}

	rewritten, err := os.ReadFile(firstPath)
	if err != nil {
		t.Fatalf("ReadFile failed: %v", err)
	}
	if string(rewritten) != sampleCanonicalLock {
		t.Errorf("rewritten lockfile mismatch:\ngot:\n%s\nwant:\n%s", string(rewritten), sampleCanonicalLock)
	}
}

func TestScrubberCheckOnlyDoesNotModifyDisk(t *testing.T) {
	initTestI18n(t)

	tmpDir := t.TempDir()
	lockPath := filepath.Join(tmpDir, "uv.lock")
	if err := os.WriteFile(lockPath, []byte(samplePrivateLock), 0o644); err != nil {
		t.Fatalf("WriteFile failed: %v", err)
	}

	scrubber := &uvlock.Scrubber{CheckOnly: true}
	res, err := scrubber.ProcessFile(context.Background(), lockPath)
	if err != nil {
		t.Fatalf("ProcessFile(--check) failed: %v", err)
	}
	if res.Modified {
		t.Errorf("res.Modified = true in CheckOnly mode")
	}
	if res.Replacements != 3 {
		t.Errorf("res.Replacements = %d, want 3", res.Replacements)
	}

	disk, err := os.ReadFile(lockPath)
	if err != nil {
		t.Fatalf("ReadFile failed: %v", err)
	}
	if string(disk) != samplePrivateLock {
		t.Errorf("file was modified on disk during CheckOnly mode")
	}
}

func TestScrubberFailsClosedOnSHA256Mismatch(t *testing.T) {
	initTestI18n(t)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{
			"urls": [
				{
					"filename": "certifi-2026.10.19.tar.gz",
					"url": "https://files.pythonhosted.org/packages/ab/cd/0123456789/certifi-2026.10.19.tar.gz",
					"digests": {"sha256": "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"}
				},
				{
					"filename": "certifi-2026.10.19-py3-none-any.whl",
					"url": "https://files.pythonhosted.org/packages/ef/01/9876543210/certifi-2026.10.19-py3-none-any.whl",
					"digests": {"sha256": %q}
				}
			]
		}`, wheelSHA)
	}))
	defer srv.Close()

	scrubber := &uvlock.Scrubber{
		Resolver: uvlock.NewHTTPPyPIResolver(srv.URL, srv.Client()),
	}
	_, _, err := scrubber.ProcessBytes(context.Background(), []byte(samplePrivateLock))
	if err == nil {
		t.Fatalf("expected sha256 mismatch error, got nil")
	}
	if !strings.Contains(err.Error(), "sha256") {
		t.Errorf("unexpected error message: %v", err)
	}
}

func TestScrubberFailsClosedWhenArtifactMissingOnPyPI(t *testing.T) {
	initTestI18n(t)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, `{"urls": []}`)
	}))
	defer srv.Close()

	scrubber := &uvlock.Scrubber{
		Resolver: uvlock.NewHTTPPyPIResolver(srv.URL, srv.Client()),
	}
	_, _, err := scrubber.ProcessBytes(context.Background(), []byte(samplePrivateLock))
	if err == nil {
		t.Fatalf("expected artifact not found error, got nil")
	}
	if !strings.Contains(err.Error(), "not found") {
		t.Errorf("unexpected error message: %v", err)
	}
}
