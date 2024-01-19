// Copyright 2023-2024 Google LLC
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
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"runtime/debug"
)

type ReportErrorEvent struct {
	Type       string `json:"@type"`
	Message    string `json:"message"`
	StackTrace string `json:"stack_trace"`
}

func main() {
	log.Println("starting server...")
	http.HandleFunc("/error", errorHandler)
	http.HandleFunc("/", handler)

	// Determine port for HTTP service.
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Println("defaulting to Port", port)
	}

	// Start HTTP server.
	log.Println("starting server using Port", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		logError("failed listening %v", err)
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	name := os.Getenv("NAME")
	hostname, _ := os.Hostname()
	if name == "" {
		name = "World"
	}
	fmt.Fprintf(w, "\nHello %s from %s! 🎉\n\n", name, hostname)
}

func errorHandler(w http.ResponseWriter, r *http.Request) {
	logError("Failed processing request %v", fmt.Errorf("failed_powering_up_flux_compensator"))
	http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
}

func logError(msg string, err error) {
	var errLine ReportErrorEvent
	errLine.Type = "type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent"
	errLine.Message = fmt.Sprintf("Error: %s", fmt.Sprintf(msg, err))
	errLine.StackTrace = string(debug.Stack())
	jsonStr, err := json.Marshal(errLine)
	if err != nil {
		log.Fatalf("json.Marshal: %v", err)
	}
	fmt.Println(string(jsonStr))
}
