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
import { state, DEFAULT_CONFIG } from "../types";
import { setupMockDOM } from "./helpers";
import { loadConfig } from "../config_module";
import { windowUtils } from "../window_utils";

describe("URL Parameter Parsing", () => {
  let searchSpy: vi.SpyInstance;

  beforeEach(() => {
    setupMockDOM();
    localStorage.clear();

    // Reset state to defaults
    // Note: AppConfig properties are readonly, so we must replace the whole object
    state.config = { ...DEFAULT_CONFIG };
    state.simulateSec = 0;

    searchSpy = vi.spyOn(windowUtils, "search", "get").mockReturnValue("");

    window.CWS_CONFIG = { supportedProtocols: ["RDP", "SSH", "VNC"] };
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("autoRedirect aliases: 'retry' and 'autoRedirect'", () => {
    // Set search parameter surgically for each test block
    searchSpy.mockReturnValue("?retry=false");
    loadConfig();
    expect(state.config.autoRedirect).toBe(false);

    searchSpy.mockReturnValue("?autoRedirect=0");
    loadConfig();
    expect(state.config.autoRedirect).toBe(false);

    searchSpy.mockReturnValue("?autoRedirect=true");
    loadConfig();
    expect(state.config.autoRedirect).toBe(true);
  });

  test("simulateDelay aliases: 'simulateSec' and 'simulateDelay'", () => {
    searchSpy.mockReturnValue("?simulateSec=45");
    loadConfig();
    expect(state.simulateSec).toBe(45);

    searchSpy.mockReturnValue("?simulateDelay=10");
    loadConfig();
    expect(state.simulateSec).toBe(10);
  });

  test("timeout and retryInterval parsing", () => {
    searchSpy.mockReturnValue("?timeout=300&retryInterval=5000");
    loadConfig();
    expect(state.config.timeoutMs).toBe(300000);
    expect(state.config.retryIntervalMs).toBe(5000);
  });

  test("protocol validation", () => {
    // loadConfig overwrites state.config with values from DEFAULT_CONFIG and CWS_CONFIG
    searchSpy.mockReturnValue("?protocol=VNC");
    loadConfig();
    expect(state.config.connectionId).toBe("VNC");

    // Should ignore invalid protocols
    searchSpy.mockReturnValue("?protocol=GOPHER");
    loadConfig();
    expect(state.config.connectionId).toBe("RDP"); // Fallback to RDP from DEFAULT_CONFIG
  });

  test("debug toggle via 'debug' param", () => {
    searchSpy.mockReturnValue("?debug=1");
    loadConfig();
    expect(state.config.showDebug).toBe(true);

    searchSpy.mockReturnValue("?debug=false");
    loadConfig();
    expect(state.config.showDebug).toBe(false);
  });
});
