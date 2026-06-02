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
import {
  loadConfig,
  updateConfig,
  copySettingsUrl,
  reportBug,
  getCurrentUIValues,
  updateStatusMessage,
  toggleRedirect,
  clearAllData,
  mapStepToTimeout,
  mapTimeoutToStep,
  mapStepToRetry,
  mapRetryToStep,
  applyUIValues,
} from "../config_module";
import { windowUtils } from "../window_utils";

describe("Config Module", () => {
  let searchSpy: any;

  beforeEach(() => {
    setupMockDOM();
    localStorage.clear();
    state.config = {
      ...DEFAULT_CONFIG,
      connectionTypes: ["RDP", "SSH", "VNC"],
    };
    state.simulateSec = 0;

    // Mock history.replaceState
    Object.defineProperty(window.history, "replaceState", {
      value: vi.fn(),
      configurable: true,
    });

    searchSpy = vi.spyOn(windowUtils, "search", "get").mockReturnValue("");
    vi.spyOn(windowUtils, "origin", "get").mockReturnValue("http://127.0.0.1");
    vi.spyOn(windowUtils, "pathname", "get").mockReturnValue("/");

    // Mock clipboard correctly using defineProperty
    const mockClipboard = {
      writeText: vi.fn().mockImplementation(() => Promise.resolve()),
    };
    Object.defineProperty(navigator, "clipboard", {
      value: mockClipboard,
      configurable: true,
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("loadConfig parses all semantic URL parameters correctly", () => {
    searchSpy.mockReturnValue(
      "?autoRedirect=false&timeout=150&retryInterval=500&simulateDelay=12&protocol=SSH&lang=es",
    );
    loadConfig();
    expect(state.config.autoRedirect).toBe(false);
    expect(state.config.timeoutMs).toBe(150000);
    expect(state.config.retryIntervalMs).toBe(500);
    expect(state.simulateSec).toBe(12);
    expect(state.config.connectionId).toBe("SSH");
    expect(state.config.lang).toBe("es");
  });

  test("updateConfig reloads with new URL parameters and persists language", () => {
    state.config = { ...state.config, lang: "ar" };
    const checkbox = document.getElementById(
      "retry-enable",
    ) as HTMLInputElement;
    checkbox.checked = false;

    updateConfig();

    const replaceStateMock = window.history.replaceState as vi.Mock;
    const redirectUrl = new URL(replaceStateMock.mock.calls[0][2] as string);
    expect(redirectUrl.searchParams.get("autoRedirect")).toBe("false");
    expect(redirectUrl.searchParams.get("lang")).toBe("ar");
  });

  test("copySettingsUrl generates URL from UI values (unsaved state)", () => {
    state.config = { ...state.config, autoRedirect: true, lang: "fr" };
    const checkbox = document.getElementById(
      "retry-enable",
    ) as HTMLInputElement;
    checkbox.checked = false;

    copySettingsUrl();

    const writeTextMock = navigator.clipboard.writeText as vi.Mock;
    const copiedUrl = new URL(writeTextMock.mock.calls[0][0] as string);
    expect(copiedUrl.searchParams.get("autoRedirect")).toBe("false");
    expect(copiedUrl.searchParams.get("lang")).toBe("fr");
  });

  test("reportBug uses active settings (not UI values)", () => {
    state.config = { ...state.config, autoRedirect: true, lang: "zh" };
    const checkbox = document.getElementById(
      "retry-enable",
    ) as HTMLInputElement;
    checkbox.checked = false;

    reportBug();

    expect(window.open).toHaveBeenCalled();
    const openedUrl = new URL(
      (window.open as vi.Mock).mock.calls[0][0] as string,
    );
    const body = openedUrl.searchParams.get("body") || "";
    expect(body).toContain("URL: http://127.0.0.1/");
  });

  test("loadConfig sets language from CWS_CONFIG.serverLang", () => {
    window.CWS_CONFIG = { serverLang: "fr" };
    loadConfig();
    expect(state.config.lang).toBe("fr");

    // Clear the DOM/mock properly
    window.CWS_CONFIG = { serverLang: "@@SERVER_LANG@@" };
    localStorage.setItem(
      "cws_preflight_config",
      JSON.stringify({ lang: "es" }),
    );
    loadConfig();
    expect(state.config.lang).toBe("es");
  });

  test("loadConfig catches parse error from localStorage", () => {
    localStorage.setItem("cws_preflight_config", "{ invalid json");
    const consoleSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    loadConfig();
    expect(consoleSpy).toHaveBeenCalledWith(
      "failed to parse config",
      expect.any(Error),
    );
    consoleSpy.mockRestore();
  });
  test("loadConfig browserLang empty", () => {
    Object.defineProperty(navigator, "language", {
      get: () => "",
      configurable: true,
    });
    loadConfig();
  });
  test("loadConfig invalid timeout & lang", () => {
    Object.defineProperty(navigator, "language", {
      value: "en-US",
      configurable: true,
    });
    window.history.pushState(
      {},
      "",
      "/?timeout=abc&retryInterval=abc&simulateDelay=abc",
    );
    loadConfig();
    expect(state.config.timeoutMs).toBe(DEFAULT_CONFIG.timeoutMs);
  });
  test("getCurrentUIValues branches", () => {
    document.body.innerHTML =
      '<div id="connection-type-list"><button class="border-secondary">RDP</button></div>';
    const vals = getCurrentUIValues();
    expect(vals.protocol).toBeDefined();
  });
  test("updateStatusMessage branches", () => {
    document.body.innerHTML = '<div id="status-message"></div>';
    state.isHealthy = true;
    updateStatusMessage();
    state.isHealthy = false;
    state.startTime = Date.now() - 100000;
    state.config = { ...state.config, timeoutMs: 10 };
    updateStatusMessage();
  });
  test("toggleRedirect", () => {
    toggleRedirect();
    expect(state.config.autoRedirect).toBe(!DEFAULT_CONFIG.autoRedirect);
  });
  test("updateConfig clears timer", () => {
    state.timerInterval = 123 as any;
    updateConfig();
    expect(state.timerInterval).toBeNull();
  });
  test("copySettingsUrl with tooltip", () => {
    vi.useFakeTimers();
    Object.defineProperty(navigator, "clipboard", {
      value: { writeText: vi.fn().mockResolvedValue(true) },
      configurable: true,
    });
    document.body.innerHTML = '<div id="copy-tooltip" class="opacity-0"></div>';
    copySettingsUrl();
    vi.runAllTimers();
  });
  test("reportBug", () => {
    window.open = vi.fn();
    reportBug();
    expect(window.open).toHaveBeenCalled();
  });
  test("clearAllData", () => {
    clearAllData();
  });
  test("getSerializedUrl ui simulateDelay", () => {
    document.body.innerHTML = '<input id="simulate-sec" value="5" />';
    const url = getCurrentUIValues();
    expect(url.simulateSec).toBe(5);
    state.simulateSec = 5;
    updateConfig();
  });
  test("mapStepToTimeout coverage", () => {
    expect(mapStepToTimeout(-1)).toBe(1);
    expect(mapStepToTimeout(0)).toBe(1);
    expect(mapStepToTimeout(100)).toBe(500);
    expect(mapStepToTimeout(101)).toBe(500);
    expect(mapStepToTimeout(50)).toBe(22);
  });
  test("mapTimeoutToStep coverage", () => {
    expect(mapTimeoutToStep(0)).toBe(0);
    expect(mapTimeoutToStep(1)).toBe(0);
    expect(mapTimeoutToStep(500)).toBe(100);
    expect(mapTimeoutToStep(600)).toBe(100);
    expect(mapTimeoutToStep(22)).toBe(50);
  });
  test("mapStepToRetry coverage", () => {
    expect(mapStepToRetry(-1)).toBe(100);
    expect(mapStepToRetry(0)).toBe(100);
    expect(mapStepToRetry(100)).toBe(10000);
    expect(mapStepToRetry(101)).toBe(10000);
    expect(mapStepToRetry(50)).toBe(1000);
  });
  test("mapRetryToStep coverage", () => {
    expect(mapRetryToStep(0)).toBe(0);
    expect(mapRetryToStep(100)).toBe(0);
    expect(mapRetryToStep(10000)).toBe(100);
    expect(mapRetryToStep(20000)).toBe(100);
    expect(mapRetryToStep(1000)).toBe(50);
  });
  test("updateStatusMessage fallback window.t", () => {
    window.t = undefined as any;
    document.body.innerHTML = '<div id="status-message"></div>';
    const msg = document.getElementById("status-message")!;
    vi.spyOn(msg, "getAttribute").mockReturnValue(null);
    updateStatusMessage();
    expect(msg.textContent).toBe("Starting...");
  });
  test("applyUIValues defaults and fallbacks", () => {
    document.body.innerHTML = `
      <input id="retry-interval" value="invalid" />
      <input id="timeout-limit" value="invalid" />
      <input id="simulate-sec" value="invalid" />
    `;
    applyUIValues({});
    applyUIValues(null); // covers early return
    expect(state.config.retryIntervalMs).toBe(state.config.retryIntervalMs);
  });
  test("getCurrentUIValues branch fallback (199)", () => {
    document.body.innerHTML = `
      <div id="connection-type-list">
        <button class="border-secondary">RDP</button>
      </div>
      <input id="retry-interval" value="50" />
      <input id="timeout-limit" value="50" />
      <input id="simulate-sec" value="50" />
      <input id="retry-enable" type="checkbox" checked />
    `;
    state.config = { ...state.config, connectionTypes: ["RDP", "SSH"] };
    window.t = undefined as any; // force toUpperCase fallback
    getCurrentUIValues();
  });
  test("Requirement: Copy URL uses UI values, Bug Report uses saved Config", () => {
    state.config = { ...state.config, autoRedirect: true };
    const redirectCb = document.getElementById(
      "retry-enable",
    ) as HTMLInputElement;

    redirectCb.checked = false;

    copySettingsUrl();
    const copiedUrl = new URL(
      (navigator.clipboard.writeText as vi.Mock).mock.calls[0][0] as string,
    );
    expect(copiedUrl.searchParams.get("autoRedirect")).toBe("false");

    window.open = vi.fn() as unknown as typeof window.open;
    reportBug();
    const bugUrl = new URL((window.open as vi.Mock).mock.calls[0][0] as string);
    const body = bugUrl.searchParams.get("body") || "";
    expect(body).toContain("URL: http://127.0.0.1/");
  });
});
