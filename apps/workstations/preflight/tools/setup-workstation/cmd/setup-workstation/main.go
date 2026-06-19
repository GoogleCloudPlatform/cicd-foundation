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

// The setup-workstation command is a utility CLI wrapper for configuring workstation configurations and template hydration.
package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"

	"github.com/GoogleCloudPlatform/cicd-foundation/apps/workstations/preflight/tools/setup-workstation/internal/setup"
)

func main() {
	code, err := runCLI()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
	}
	os.Exit(code)
}

func runCLI() (int, error) {
	opts, needsSetup := parseFlags()

	if needsSetup {
		if err := setup.CheckRunnable(opts); err != nil {
			return 0, nil // Setup is required (so we can run and show the error)
		}
		if !opts.ForceReset && setup.IsDone(opts.HomeDir) {
			return 1, nil
		}
		return 0, nil
	}

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	if err := setup.Run(ctx, opts, nil); err != nil {
		return 1, err
	}
	return 0, nil
}
