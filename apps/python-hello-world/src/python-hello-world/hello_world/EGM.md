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

# hello_world

## Overview

Minimal Flask web application package (`hello_world`) serving a greeting message
on the root (`/`) HTTP endpoint, parameterized by the `NAME` environment
variable.

## Interface

- `hello_world.app.app`: Module-level `Flask(__name__)` application instance
  registered with the `'/'` route.
- `hello_world.app.index() -> str`: HTTP route handler for `'/'` returning
  `'Hello <NAME> from Python!'`.
- `NAME`: Optional environment variable read from `os.environ` to customize
  the greeting target (defaults to `'World'`).

## Invariants

- Defaults the greeting target to `'World'` when the `'NAME'` environment
  variable is not set in `os.environ`.
- Always returns a string formatted as `'Hello ' + name + ' from Python!'`.

## Side Effects

- Module import instantiates a module-level `Flask(__name__)` object (`app`)
  and registers the `'/'` route.
- Calling `index()` reads the `'NAME'` variable from `os.environ`.
