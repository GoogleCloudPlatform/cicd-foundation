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

import { vi } from "vitest";
import { state } from "../types";
import { loadConfig } from "../config_module";
import { windowUtils } from "../window_utils";

describe("Language Priority Logic", () => {
  let searchSpy: any;

  beforeEach(() => {
    localStorage.clear();
    window.CWS_CONFIG = undefined;

    searchSpy = vi.spyOn(windowUtils, "search", "get").mockReturnValue("");

    // Mock navigator.language
    Object.defineProperty(navigator, "language", {
      get: () => "en-US",
      configurable: true,
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("Browser language is the base default", () => {
    loadConfig();
    expect(state.config.lang).toBe("en");
  });

  test("Local storage overrides browser default (Low Priority)", () => {
    localStorage.setItem(
      "cws_preflight_config",
      JSON.stringify({ lang: "fr" }),
    );
    loadConfig();
    expect(state.config.lang).toBe("fr");
  });

  test("Server meta overrides local storage (Medium Priority)", () => {
    // 1. Set local storage to French
    localStorage.setItem(
      "cws_preflight_config",
      JSON.stringify({ lang: "fr" }),
    );

    // 2. Set Server meta to Arabic
    window.CWS_CONFIG = { serverLang: "ar" };

    loadConfig();

    // Server meta MUST win over local storage for operational accuracy
    expect(state.config.lang).toBe("ar");
  });

  test("URL parameter overrides everything (Highest Priority)", () => {
    // 1. Set local storage to French
    localStorage.setItem(
      "cws_preflight_config",
      JSON.stringify({ lang: "fr" }),
    );

    // 2. Set Server meta to Arabic
    window.CWS_CONFIG = { serverLang: "ar" };

    // 3. Set URL param to Spanish
    searchSpy.mockReturnValue("?lang=es");

    loadConfig();
    expect(state.config.lang).toBe("es");
  });
});
