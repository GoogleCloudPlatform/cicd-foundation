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

# python-hello-world

## Overview

Python container module (`hello-world` v0.1.0, `requires-python = ">=3.10"`)
packaging the `hello_world` Flask web application with Hatchling
(`pyproject.toml`), locked dependency manifests (`requirements.txt`, `uv.lock`),
and a Buildpacks `Procfile` entrypoint.

## Subdirectories & Boundaries

- `hello_world`: [`./hello_world/EGM.md`](./hello_world/EGM.md) - Flask web
  application package exposing `app` and `index()` on `/`.

## Interface

- `Procfile`: Defines the `web` process entrypoint
  (`FLASK_APP=hello_world/app.py; FLASK_RUN_PORT=8080; python -m flask
--app=$FLASK_APP run --host=0.0.0.0 --port=$FLASK_RUN_PORT`).
- `pyproject.toml`: Python project metadata (`name = "hello-world"`,
  `version = "0.1.0"`, `requires-python = ">=3.10"`, dependencies
  `Flask>=3.1.3`, `Jinja2>=3.1.6`, and `Werkzeug>=3.1.9`, build backend
  `hatchling.build`).
- `requirements.txt` & `uv.lock`: Pinned dependency specifications used by
  Cloud Buildpacks and `uv`.
- [`./hello_world/EGM.md`](./hello_world/EGM.md): Flask application instance
  (`hello_world.app.app`) and route handler (`hello_world.app.index()`).

## Invariants

- Requires Python `>=3.10`, `Flask>=3.1.3`, `Jinja2>=3.1.6`, and
  `Werkzeug>=3.1.9`.
- `Procfile` binds the Flask development server to `0.0.0.0:8080` with
  `FLASK_APP=hello_world/app.py`.

## Side Effects

- Executing the `web` process in `Procfile` sets `FLASK_APP` and
  `FLASK_RUN_PORT` and starts a Flask HTTP server listening on `0.0.0.0:8080`.
