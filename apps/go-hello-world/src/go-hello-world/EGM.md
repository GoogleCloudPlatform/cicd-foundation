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

# go-hello-world

## Overview

Sample Go HTTP server package (`package main`, module
`github.com/googlecloudplatform/cicd-foundation/apps/go-hello-world`, Go
`1.22.5`) that serves a customizable greeting on `/` and emits structured JSON
error events formatted for Cloud Error Reporting on `/error`.

## Interface

- `type ReportErrorEvent struct`: JSON-serializable payload (`@type`,
  `message`, `stack_trace`) formatted for Google Cloud Error Reporting
  (`type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent`).
- `GET /` (`handler`): HTTP handler responding with `\nHello <NAME> from Go
🎉 - running @ <hostname>\n\n`.
- `GET /error` (`errorHandler`): HTTP handler that emits a structured
  `ReportedErrorEvent` JSON log for simulated error
  `failed_powering_up_flux_compensator` and responds with HTTP `500 Internal
Server Error`.
- `PORT`: Optional environment variable configuring the TCP port for the HTTP
  server (defaults to `"8080"`).
- `NAME`: Optional environment variable customizing the greeting target in the
  `/` handler response (defaults to `"World"`).

## Invariants

- `PORT` defaults to `"8080"` when the `PORT` environment variable is unset or
  empty.
- `NAME` defaults to `"World"` when the `NAME` environment variable is unset
  or empty.
- `logError` always sets `ReportErrorEvent.Type` to
  `"type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent"`,
  prefixes `ReportErrorEvent.Message` with `"Error: "`, and populates
  `ReportErrorEvent.StackTrace` from `runtime/debug.Stack()`.

## Side Effects

- Registers `/error` and `/` handlers on the global `net/http`
  `DefaultServeMux`.
- Binds and listens on TCP address `":" + port` via `http.ListenAndServe`.
- Reads environment variables `PORT` and `NAME` via `os.Getenv` and resolves
  the host's name via `os.Hostname`.
- Writes operational logs via the standard `log` package, prints serialized
  `ReportErrorEvent` JSON payloads to stdout via `fmt.Println`, and terminates
  the process via `log.Fatalf` if `json.Marshal` fails inside `logError`.
