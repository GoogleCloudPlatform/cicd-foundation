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

// Package uvlock scrubs non-public package registry URLs in uv.lock files back
// to canonical public PyPI URLs while enforcing SHA-256 digest parity.
package uvlock

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"path"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/GoogleCloudPlatform/cicd-foundation/skills/persona-oss/scripts/internal/i18n"
)

const (
	// CanonicalPyPIRegistry is the standard upstream Simple API index recorded by uv.
	CanonicalPyPIRegistry = "https://pypi.org/simple"

	// CanonicalPyPICDNPrefix is the required prefix for public PyPI distribution artifacts.
	CanonicalPyPICDNPrefix = "https://files.pythonhosted.org/"

	// DefaultPyPIAPIBase is the default Warehouse JSON metadata endpoint base URL.
	DefaultPyPIAPIBase = "https://pypi.org/pypi"

	defaultMaxConcurrency = 12
	defaultHTTPTimeout    = 30 * time.Second
)

var (
	tomlSectionRe = regexp.MustCompile(`^\[`)
	packageNameRe = regexp.MustCompile(`^name\s*=\s*"([^"]+)"`)
	packageVerRe  = regexp.MustCompile(`^version\s*=\s*"([^"]+)"`)
	registryRe    = regexp.MustCompile(`(source\s*=\s*\{\s*registry\s*=\s*)"([^"]+)"(\s*\})`)
	urlFieldRe    = regexp.MustCompile(`(\burl\s*=\s*)"([^"]+)"`)
	sha256FieldRe = regexp.MustCompile(`\bhash\s*=\s*"sha256:([0-9a-fA-F]{64})"`)
)

// ArtifactInfo holds the canonical upstream URL and SHA-256 hex digest for a distribution file.
type ArtifactInfo struct {
	URL    string
	SHA256 string
}

// MetadataResolver resolves distribution filenames to upstream PyPI URLs and digests.
type MetadataResolver interface {
	ResolveRelease(ctx context.Context, pkg, version string) (map[string]ArtifactInfo, error)
}

// HTTPPyPIResolver queries the PyPI JSON API and caches release metadata in memory.
type HTTPPyPIResolver struct {
	APIBase string
	Client  *http.Client

	mu    sync.Mutex
	cache map[string]map[string]ArtifactInfo
}

// NewHTTPPyPIResolver constructs a cached PyPI metadata resolver.
func NewHTTPPyPIResolver(apiBase string, client *http.Client) *HTTPPyPIResolver {
	if strings.TrimSpace(apiBase) == "" {
		apiBase = DefaultPyPIAPIBase
	}
	if client == nil {
		client = &http.Client{Timeout: defaultHTTPTimeout}
	}
	return &HTTPPyPIResolver{
		APIBase: strings.TrimRight(apiBase, "/"),
		Client:  client,
		cache:   make(map[string]map[string]ArtifactInfo),
	}
}

type pypiFileEntry struct {
	Filename string `json:"filename"`
	URL      string `json:"url"`
	Digests  struct {
		SHA256 string `json:"sha256"`
	} `json:"digests"`
}

type pypiReleaseResponse struct {
	URLs     []pypiFileEntry            `json:"urls"`
	Releases map[string][]pypiFileEntry `json:"releases"`
}

// ResolveRelease fetches and caches distribution metadata for pkg@version.
func (r *HTTPPyPIResolver) ResolveRelease(ctx context.Context, pkg, version string) (map[string]ArtifactInfo, error) {
	cacheKey := pkg + "@" + version

	r.mu.Lock()
	if cached, ok := r.cache[cacheKey]; ok {
		r.mu.Unlock()
		return cached, nil
	}
	r.mu.Unlock()

	endpoint := fmt.Sprintf("%s/%s/%s/json", r.APIBase, url.PathEscape(pkg), url.PathEscape(version))
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Accept", "application/json")

	resp, err := r.Client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("http request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected http status %d", resp.StatusCode)
	}

	var payload pypiReleaseResponse
	if err := json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		return nil, fmt.Errorf("invalid json payload: %w", err)
	}

	artifacts := make(map[string]ArtifactInfo, len(payload.URLs))
	for _, entry := range payload.URLs {
		if entry.Filename != "" {
			artifacts[entry.Filename] = ArtifactInfo{
				URL:    entry.URL,
				SHA256: entry.Digests.SHA256,
			}
		}
	}
	for _, entries := range payload.Releases {
		for _, entry := range entries {
			if entry.Filename != "" {
				if _, exists := artifacts[entry.Filename]; !exists {
					artifacts[entry.Filename] = ArtifactInfo{
						URL:    entry.URL,
						SHA256: entry.Digests.SHA256,
					}
				}
			}
		}
	}

	r.mu.Lock()
	r.cache[cacheKey] = artifacts
	r.mu.Unlock()

	return artifacts, nil
}

// ScrubResult summarizes the inspection or rewrite outcome for a single uv.lock file.
type ScrubResult struct {
	Path         string
	Replacements int
	Modified     bool
}

// Scrubber inspects and rewrites non-public registry URLs in uv.lock files.
type Scrubber struct {
	Resolver       MetadataResolver
	CheckOnly      bool
	MaxConcurrency int
}

type releaseKey struct {
	pkg     string
	version string
}

// ProcessBytes inspects raw uv.lock bytes and rewrites non-public registry URLs when CheckOnly is false.
func (s *Scrubber) ProcessBytes(ctx context.Context, content []byte) ([]byte, int, error) {
	rawLines := bytes.Split(content, []byte("\n"))
	lines := make([]string, len(rawLines))
	for i, b := range rawLines {
		lines[i] = string(b)
	}

	neededReleases := make(map[releaseKey]struct{})
	neededReplacements := 0

	currentPkg := ""
	currentVersion := ""
	isRegistryPkg := false

	for _, line := range lines {
		trimmed := strings.TrimRight(line, "\r")
		if tomlSectionRe.MatchString(trimmed) {
			currentPkg = ""
			currentVersion = ""
			isRegistryPkg = false
			continue
		}
		if currentPkg == "" {
			if m := packageNameRe.FindStringSubmatch(trimmed); len(m) > 1 {
				currentPkg = m[1]
				continue
			}
		}
		if currentVersion == "" {
			if m := packageVerRe.FindStringSubmatch(trimmed); len(m) > 1 {
				currentVersion = m[1]
				continue
			}
		}
		if m := registryRe.FindStringSubmatch(trimmed); len(m) > 2 {
			isRegistryPkg = true
			if m[2] != CanonicalPyPIRegistry {
				neededReplacements++
			}
			continue
		}
		if isRegistryPkg {
			if m := urlFieldRe.FindStringSubmatch(trimmed); len(m) > 2 {
				if !strings.HasPrefix(m[2], CanonicalPyPICDNPrefix) {
					neededReplacements++
					if currentPkg != "" && currentVersion != "" {
						neededReleases[releaseKey{pkg: currentPkg, version: currentVersion}] = struct{}{}
					}
				}
			}
		}
	}

	if neededReplacements == 0 || s.CheckOnly {
		return content, neededReplacements, nil
	}

	if s.Resolver == nil {
		return nil, 0, errors.New("metadata resolver is nil")
	}

	releaseData, err := s.prefetchReleases(ctx, neededReleases)
	if err != nil {
		return nil, 0, err
	}

	outLines := make([]string, len(lines))
	replacements := 0
	currentPkg = ""
	currentVersion = ""
	isRegistryPkg = false

	for idx, line := range lines {
		hasCR := strings.HasSuffix(line, "\r")
		trimmed := strings.TrimRight(line, "\r")

		if tomlSectionRe.MatchString(trimmed) {
			currentPkg = ""
			currentVersion = ""
			isRegistryPkg = false
			outLines[idx] = line
			continue
		}
		if currentPkg == "" {
			if m := packageNameRe.FindStringSubmatch(trimmed); len(m) > 1 {
				currentPkg = m[1]
				outLines[idx] = line
				continue
			}
		}
		if currentVersion == "" {
			if m := packageVerRe.FindStringSubmatch(trimmed); len(m) > 1 {
				currentVersion = m[1]
				outLines[idx] = line
				continue
			}
		}
		if m := registryRe.FindStringSubmatch(trimmed); len(m) > 2 {
			isRegistryPkg = true
			oldRegistry := m[2]
			if oldRegistry != CanonicalPyPIRegistry {
				updated := strings.Replace(trimmed, `"`+oldRegistry+`"`, `"`+CanonicalPyPIRegistry+`"`, 1)
				if hasCR {
					updated += "\r"
				}
				outLines[idx] = updated
				replacements++
				continue
			}
			outLines[idx] = line
			continue
		}

		if isRegistryPkg {
			if m := urlFieldRe.FindStringSubmatch(trimmed); len(m) > 2 {
				oldURL := m[2]
				if !strings.HasPrefix(oldURL, CanonicalPyPICDNPrefix) {
					filename := extractFilename(oldURL)
					key := releaseKey{pkg: currentPkg, version: currentVersion}
					artifacts := releaseData[key]
					artifact, ok := artifacts[filename]
					if !ok {
						return nil, 0, errors.New(i18n.TF("error_artifact_not_found", map[string]any{
							"Filename": filename,
							"Package":  currentPkg,
							"Version":  currentVersion,
						}))
					}
					if !strings.HasPrefix(artifact.URL, CanonicalPyPICDNPrefix) {
						return nil, 0, errors.New(i18n.TF("error_unexpected_cdn_url", map[string]any{
							"URL":     artifact.URL,
							"Package": currentPkg,
							"Version": currentVersion,
						}))
					}
					if hm := sha256FieldRe.FindStringSubmatch(trimmed); len(hm) > 1 && artifact.SHA256 != "" {
						expectedSHA := hm[1]
						if !strings.EqualFold(expectedSHA, artifact.SHA256) {
							return nil, 0, errors.New(i18n.TF("error_hash_mismatch", map[string]any{
								"Package":  currentPkg,
								"Version":  currentVersion,
								"Filename": filename,
								"Expected": expectedSHA,
								"Actual":   artifact.SHA256,
							}))
						}
					}

					updated := strings.Replace(trimmed, `"`+oldURL+`"`, `"`+artifact.URL+`"`, 1)
					if hasCR {
						updated += "\r"
					}
					outLines[idx] = updated
					replacements++
					continue
				}
			}
		}

		outLines[idx] = line
	}

	return []byte(strings.Join(outLines, "\n")), replacements, nil
}

func (s *Scrubber) prefetchReleases(ctx context.Context, keys map[releaseKey]struct{}) (map[releaseKey]map[string]ArtifactInfo, error) {
	results := make(map[releaseKey]map[string]ArtifactInfo, len(keys))
	if len(keys) == 0 {
		return results, nil
	}

	limit := s.MaxConcurrency
	if limit <= 0 {
		limit = defaultMaxConcurrency
	}

	fetchCtx, cancel := context.WithCancel(ctx)
	defer cancel()

	sem := make(chan struct{}, limit)
	var wg sync.WaitGroup
	var mu sync.Mutex
	var firstErr error

	for k := range keys {
		wg.Add(1)
		go func(rk releaseKey) {
			defer wg.Done()
			select {
			case sem <- struct{}{}:
				defer func() { <-sem }()
			case <-fetchCtx.Done():
				return
			}

			artifacts, err := s.Resolver.ResolveRelease(fetchCtx, rk.pkg, rk.version)
			mu.Lock()
			defer mu.Unlock()
			if err != nil {
				if firstErr == nil {
					firstErr = errors.New(i18n.TF("error_resolve_metadata", map[string]any{
						"Package": rk.pkg,
						"Version": rk.version,
						"Error":   err,
					}))
					cancel()
				}
				return
			}
			results[rk] = artifacts
		}(k)
	}

	wg.Wait()
	if firstErr != nil {
		return nil, firstErr
	}
	return results, nil
}

// ProcessFile reads a uv.lock file from disk and rewrites non-public registry URLs in place when CheckOnly is false.
func (s *Scrubber) ProcessFile(ctx context.Context, filePath string) (ScrubResult, error) {
	info, err := os.Stat(filePath)
	if err != nil {
		return ScrubResult{}, errors.New(i18n.TF("error_read_lockfile", map[string]any{
			"Path":  filePath,
			"Error": err,
		}))
	}

	raw, err := os.ReadFile(filePath)
	if err != nil {
		return ScrubResult{}, errors.New(i18n.TF("error_read_lockfile", map[string]any{
			"Path":  filePath,
			"Error": err,
		}))
	}

	updated, count, err := s.ProcessBytes(ctx, raw)
	if err != nil {
		return ScrubResult{}, err
	}

	if count == 0 || s.CheckOnly {
		return ScrubResult{
			Path:         filePath,
			Replacements: count,
			Modified:     false,
		}, nil
	}

	if err := os.WriteFile(filePath, updated, info.Mode().Perm()); err != nil {
		return ScrubResult{}, errors.New(i18n.TF("error_write_lockfile", map[string]any{
			"Path":  filePath,
			"Error": err,
		}))
	}

	return ScrubResult{
		Path:         filePath,
		Replacements: count,
		Modified:     true,
	}, nil
}

func extractFilename(rawURL string) string {
	parsed, err := url.Parse(rawURL)
	if err == nil && parsed.Path != "" {
		base := path.Base(parsed.Path)
		if unescaped, uErr := url.PathUnescape(base); uErr == nil && unescaped != "" {
			return unescaped
		}
		return base
	}
	idx := strings.LastIndex(rawURL, "/")
	if idx >= 0 && idx+1 < len(rawURL) {
		return rawURL[idx+1:]
	}
	return rawURL
}
