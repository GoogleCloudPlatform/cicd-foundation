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

# Go Style Guide

This guide defines the standards for Go code written within this repository, particularly for high-performance automation scripts and `pre-commit` hooks.

We do not reinvent the wheel here. All Go code in this repository MUST strictly adhere to the following authoritative public guidelines:

1.  **[Effective Go](https://go.dev/doc/effective_go):** The foundational document for writing clear, idiomatic Go code.
2.  **[Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments):** A checklist of common mistakes made by Go programmers, serving as a supplement to Effective Go.
3.  **[Google Go Style Guide](https://google.github.io/styleguide/go/):** Google's internal style guide for Go, detailing specific conventions and best practices.

## Repository-Specific Rules

While the documents above cover 99% of our requirements, the following rules apply specifically to the context of this repository:

### 1. Tooling and Formatting

- **Mandatory Formatter:** All Go code MUST be formatted using `gofmt` or `goimports` before committing.
- **Modules:** Always use Go Modules (`go.mod` and `go.sum`) for dependency management, even for standalone scripts.

### 2. Performance (For Scripts)

Because Go is often used here for `pre-commit` hooks where execution time directly blocks the developer workflow:

- **Concurrency:** Use `goroutines` to process files in parallel whenever performing I/O bound tasks across the codebase (e.g., linting, formatting).
- **Bytes vs Strings:** When doing heavy text manipulation, prefer using `[]byte` and the `bytes` package to avoid unnecessary string allocations and garbage collection overhead.

### 3. Strictly Enforced Idioms (Readability Pitfalls)

To ensure consistency and reduce cognitive load, the following standard Go idioms are strictly enforced during code review:

- **Naming Conventions:** Never use the variable name `ctx` for anything other than `context.Context`. For domain-specific contexts, use descriptive names (e.g., `seepageCtx`, `appCtx`).
- **Error Formatting:** Error strings passed to `fmt.Errorf` or `errors.New` MUST be lowercase and MUST NOT end with punctuation (e.g., use `fmt.Errorf("failed to load file")` instead of `fmt.Errorf("Failed to load file.")`).
- **Test Helpers:** Any test utility function that calls `t.Fatal` or `t.Error` MUST call `t.Helper()` at the beginning of the function to ensure correct stack traces.
- **Package Documentation:** Every exported package MUST have a descriptive package comment immediately preceding the `package` declaration.
