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

import { CONFIG_KEY, DEFAULT_RETRY_INTERVAL_MS } from "./constants";
import {
  AppConfig,
  DEFAULT_CONFIG,
  state,
  updateState,
  resetSessionState,
} from "./types";
import { windowUtils } from "./window_utils";

/**
 * Interface for the UI form values.
 */
interface UIValues {
  readonly autoRedirect: boolean;
  readonly showDebug: boolean;
  readonly timeoutMs: number;
  readonly retryIntervalMs: number;
  readonly simulateSec: number;
  readonly lang: string;
  readonly protocol: string;
  readonly hostname: string;
}

/**
 * Maps a linear slider step (0-100) to a logarithmic timeout value (1s to 500s).
 * @param step The linear step value.
 * @returns The logarithmic timeout in seconds.
 */
export function mapStepToTimeout(step: number): number {
  if (step <= 0) return 1;
  if (step >= 100) return 500;
  return Math.round(Math.exp((step * Math.log(500)) / 100));
}

/**
 * Maps a logarithmic timeout value (1s to 500s) back to a linear slider step (0-100).
 * @param val The timeout value in seconds.
 * @returns The linear slider step.
 */
export function mapTimeoutToStep(val: number): number {
  if (val <= 1) return 0;
  if (val >= 500) return 100;
  return Math.round((Math.log(val) * 100) / Math.log(500));
}

/**
 * Maps a linear slider step (0-100) to a logarithmic retry interval (100ms to 10,000ms).
 * @param step The linear step value.
 * @returns The logarithmic retry interval in milliseconds.
 */
export function mapStepToRetry(step: number): number {
  if (step <= 0) return 100;
  if (step >= 100) return 10000;
  return Math.round(Math.exp((step * Math.log(100)) / 100 + Math.log(100)));
}

/**
 * Maps a logarithmic retry value (100ms to 10,000ms) back to a linear slider step (0-100).
 * @param val The retry interval in milliseconds.
 * @returns The linear slider step.
 */
export function mapRetryToStep(val: number): number {
  if (val <= 100) return 0;
  if (val >= 10000) return 100;
  return Math.round(((Math.log(val) - Math.log(100)) * 100) / Math.log(100));
}

/**
 * Loads the application configuration from defaults, environment, and persistent storage.
 */
export function loadConfig(): void {
  let config: AppConfig = { ...DEFAULT_CONFIG };
  const browserLang = navigator.language.split("-")[0];
  if (browserLang) {
    config = { ...config, lang: browserLang };
  }

  const savedStr = localStorage.getItem(CONFIG_KEY);
  if (savedStr) {
    try {
      const saved = JSON.parse(savedStr) as Partial<AppConfig>;
      // Apply saved config but ensure sensitive/dynamic fields are not overwritten from storage
      config = {
        ...config,
        ...saved,
        hostname: config.hostname,
        uplink: config.uplink,
        clientIp: config.clientIp,
      };
    } catch (e) {
      console.error("failed to parse config", e);
    }
  }

  if (window.CWS_CONFIG) {
    config = {
      ...config,
      hostname: window.CWS_CONFIG.hostname ?? config.hostname,
      uplink: window.CWS_CONFIG.uplink ?? config.uplink,
      connectionTypes:
        window.CWS_CONFIG.supportedProtocols ?? config.connectionTypes,
      clientIp: window.CWS_CONFIG.clientIp ?? config.clientIp,
    };
    const sLang = window.CWS_CONFIG.serverLang;
    if (sLang && sLang !== "@@SERVER_LANG@@") {
      config = { ...config, lang: sLang };
    }
  }

  const params = new URLSearchParams(windowUtils.search);
  const redirectParam = params.get("autoRedirect") ?? params.get("retry");
  if (redirectParam !== null) {
    config = {
      ...config,
      autoRedirect: !(redirectParam === "0" || redirectParam === "false"),
    };
  }

  const timeoutParam = params.get("timeout");
  if (timeoutParam) {
    const val = parseInt(timeoutParam, 10);
    if (!isNaN(val)) {
      config = { ...config, timeoutMs: val * 1000 };
    }
  }

  const retryIntParam = params.get("retryInterval");
  if (retryIntParam) {
    const val = parseInt(retryIntParam, 10);
    if (!isNaN(val) && val > 0) {
      config = { ...config, retryIntervalMs: val };
    }
  } else if (!savedStr) {
    config = { ...config, retryIntervalMs: DEFAULT_RETRY_INTERVAL_MS };
  }

  const simulateParam =
    params.get("simulateDelay") ?? params.get("simulateSec");
  if (simulateParam) {
    const val = parseInt(simulateParam, 10);
    if (!isNaN(val) && val >= 0) {
      updateState({ simulateSec: val });
    }
  }

  const protocolParam = params.get("protocol");
  if (protocolParam && config.connectionTypes.includes(protocolParam)) {
    config = { ...config, connectionId: protocolParam };
  }

  const langParam = params.get("lang");
  if (langParam) {
    config = { ...config, lang: langParam };
  }

  const debugParam = params.get("debug");
  if (debugParam !== null) {
    config = {
      ...config,
      showDebug: debugParam === "true" || debugParam === "1",
    };
  }

  updateState({ config });
}

/**
 * Persists the current configuration to local storage.
 */
export function saveConfig(): void {
  localStorage.setItem(CONFIG_KEY, JSON.stringify(state.config));
}

/**
 * Captures the current values from UI elements.
 * @returns A snapshot of the values currently present in the UI.
 */
export function getCurrentUIValues(): UIValues {
  const redirectEl = document.getElementById(
    "retry-enable",
  ) as HTMLInputElement | null;
  const debugEl = document.getElementById(
    "debug-enable",
  ) as HTMLInputElement | null;
  const timeoutEl = document.getElementById(
    "timeout-limit",
  ) as HTMLInputElement | null;
  const intervalEl = document.getElementById(
    "retry-interval",
  ) as HTMLInputElement | null;
  const simulateEl = document.getElementById(
    "simulate-sec",
  ) as HTMLInputElement | null;

  // Read selected protocol from the connection list UI state
  let selectedProtocol = state.config.connectionId;
  const connectionList = document.getElementById("connection-type-list");
  if (connectionList) {
    const activeBtn = connectionList.querySelector("button.border-secondary");
    if (activeBtn?.textContent) {
      // Find the protocol key that matches the full name
      const found = state.config.connectionTypes.find(
        (t) =>
          window.t?.(`label_protocol_${t.toLowerCase()}`, t.toUpperCase()) ===
            activeBtn.textContent ||
          t.toUpperCase() === activeBtn.textContent?.toUpperCase(),
      );
      if (found) selectedProtocol = found;
    }
  }

  return {
    autoRedirect: redirectEl ? redirectEl.checked : state.config.autoRedirect,
    showDebug: debugEl ? debugEl.checked : state.config.showDebug,
    timeoutMs: timeoutEl
      ? mapStepToTimeout(parseInt(timeoutEl.value, 10)) * 1000
      : state.config.timeoutMs,
    retryIntervalMs: intervalEl
      ? mapStepToRetry(parseInt(intervalEl.value, 10))
      : state.config.retryIntervalMs,
    simulateSec: simulateEl
      ? parseInt(simulateEl.value, 10)
      : state.simulateSec,
    lang: state.config.lang,
    protocol: selectedProtocol,
    hostname: state.config.hostname,
  };
}

/**
 * Re-applies a snapshot of values to the UI elements.
 * @param data The UI values to apply.
 */
export function applyUIValues(data: unknown): void {
  if (!data || typeof data !== "object") return;
  const uiData = data as Partial<UIValues>;

  const redirectEnableEl = document.getElementById(
    "retry-enable",
  ) as HTMLInputElement | null;
  const debugEnableEl = document.getElementById(
    "debug-enable",
  ) as HTMLInputElement | null;
  const timeoutLimitEl = document.getElementById(
    "timeout-limit",
  ) as HTMLInputElement | null;
  const timeoutValueEl = document.getElementById("timeout-value");
  const simulateSecEl = document.getElementById(
    "simulate-sec",
  ) as HTMLInputElement | null;
  const simulateValueEl = document.getElementById("simulate-value");
  const retryIntervalEl = document.getElementById(
    "retry-interval",
  ) as HTMLInputElement | null;
  const retryValueEl = document.getElementById("retry-value");

  if (redirectEnableEl && uiData.autoRedirect !== undefined) {
    redirectEnableEl.checked = uiData.autoRedirect;
  }
  if (debugEnableEl && uiData.showDebug !== undefined) {
    debugEnableEl.checked = uiData.showDebug;
  }

  if (retryIntervalEl && uiData.retryIntervalMs !== undefined) {
    retryIntervalEl.value = mapRetryToStep(uiData.retryIntervalMs).toString();
    if (retryValueEl) {
      retryValueEl.textContent = `${Math.round(uiData.retryIntervalMs)}ms`;
    }
  }

  if (timeoutLimitEl && uiData.timeoutMs !== undefined) {
    const s = Math.round(uiData.timeoutMs / 1000);
    timeoutLimitEl.value = mapTimeoutToStep(s).toString();
    if (timeoutValueEl) {
      timeoutValueEl.textContent = `${s}s`;
    }
  }

  if (simulateSecEl && uiData.simulateSec !== undefined) {
    simulateSecEl.value = uiData.simulateSec.toString();
    if (simulateValueEl) {
      simulateValueEl.textContent = `${uiData.simulateSec}s`;
    }
  }

  if (uiData.protocol !== undefined) {
    updateState({ config: { ...state.config, connectionId: uiData.protocol } });
  }
}

/**
 * Generates a serialized URL for sharing or persistence.
 * @param source Whether to use the current 'config' state or 'ui' form values.
 * @returns The serialized URL string.
 */
function getSerializedUrl(source: "config" | "ui"): string {
  const url = new URL(windowUtils.origin + windowUtils.pathname);
  const data =
    source === "ui"
      ? getCurrentUIValues()
      : {
          autoRedirect: state.config.autoRedirect,
          showDebug: state.config.showDebug,
          timeoutMs: state.config.timeoutMs,
          retryIntervalMs: state.config.retryIntervalMs,
          protocol: state.config.connectionId,
          lang: state.config.lang,
          simulateSec: state.simulateSec,
        };

  url.searchParams.set("autoRedirect", data.autoRedirect.toString());
  url.searchParams.set("debug", data.showDebug.toString());
  url.searchParams.set("timeout", Math.round(data.timeoutMs / 1000).toString());
  url.searchParams.set(
    "retryInterval",
    Math.round(data.retryIntervalMs).toString(),
  );
  url.searchParams.set("protocol", data.protocol);
  url.searchParams.set("lang", data.lang);
  if (data.simulateSec > 0) {
    url.searchParams.set("simulateDelay", data.simulateSec.toString());
  }

  return url.toString();
}

/**
 * Synchronizes UI elements with the global application configuration.
 */
export function updateUIFromConfig(): void {
  applyUIValues({
    autoRedirect: state.config.autoRedirect,
    showDebug: state.config.showDebug,
    retryIntervalMs: state.config.retryIntervalMs,
    timeoutMs: state.config.timeoutMs,
    simulateSec: state.simulateSec,
  });

  const activeLangEl = document.getElementById("display-active-lang");
  if (activeLangEl) {
    const currentTranslation = state.translations[state.config.lang];
    if (currentTranslation) {
      activeLangEl.textContent = currentTranslation.native;
      activeLangEl.removeAttribute("data-i18n");
    }
  }
  window.syncRetryIntervalState?.();
  window.renderConnectionTypeList?.();
  updateStatusMessage();
}

/**
 * Updates the user-facing status message based on health and timeout state.
 */
export function updateStatusMessage(): void {
  const msgEl = document.getElementById("status-message");
  if (!msgEl) return;
  const elapsedMs = Date.now() - state.startTime;
  const isTimeout = elapsedMs > state.config.timeoutMs;
  if (state.isHealthy) {
    msgEl.setAttribute("data-i18n", "status_message_ready");
  } else if (isTimeout) {
    msgEl.setAttribute("data-i18n", "status_message_timeout");
  } else {
    msgEl.setAttribute(
      "data-i18n",
      state.config.autoRedirect ? "status_message" : "status_message_manual",
    );
  }
  const key = msgEl.getAttribute("data-i18n") || "status_message";
  msgEl.textContent = window.t?.(key, "Starting...") || "Starting...";
}

/**
 * Toggles the automatic redirect/retry behavior.
 */
export function toggleRedirect(): void {
  updateState({
    config: { ...state.config, autoRedirect: !state.config.autoRedirect },
  });
  saveConfig();
  updateUIFromConfig();
  window.history.replaceState({}, "", getSerializedUrl("config"));
}

/** Alias for toggleRedirect to match expected window API. */
export const toggleRetry = toggleRedirect;

/**
 * Commits the current UI form values to the global config and triggers a session reset.
 */
export function updateConfig(): void {
  const current = getCurrentUIValues();
  updateState({
    config: {
      ...state.config,
      autoRedirect: current.autoRedirect,
      showDebug: current.showDebug,
      retryIntervalMs: current.retryIntervalMs,
      timeoutMs: current.timeoutMs,
      connectionId: current.protocol,
    },
    simulateSec: current.simulateSec,
    uiTransient: null,
  });

  saveConfig();
  window.history.replaceState({}, "", getSerializedUrl("config"));

  if (state.timerInterval) {
    clearTimeout(state.timerInterval);
    updateState({ timerInterval: null });
  }
  resetSessionState();

  window.startHealthChecks?.();
  window.updateTimer?.();
  window.updateUIFromConfig?.();
  window.updateDebugInfo?.();
  window.resetUIVisuals?.();
  window.updateDisplayData?.();
}

/**
 * Clears all local storage and resets the application to its default state.
 */
export function resetConfig(): void {
  updateState({ uiTransient: null });
  localStorage.clear();
  windowUtils.href = windowUtils.pathname;
}

/** Alias for resetConfig. */
export function clearAllData(): void {
  resetConfig();
}

/**
 * Copies a link to the current UI configuration to the clipboard.
 */
export function copySettingsUrl(): void {
  const url = getSerializedUrl("ui");
  navigator.clipboard.writeText(url).then(() => {
    const tooltip = document.getElementById("copy-tooltip");
    if (tooltip) {
      tooltip.textContent = "Copied!";
      tooltip.classList.remove("opacity-0");
      setTimeout(() => tooltip.classList.add("opacity-0"), 2000);
    }
  });
}

/**
 * Opens the GitHub issue tracker with pre-filled configuration details.
 */
export function reportBug(): void {
  const url = getSerializedUrl("config");
  const body = `URL: ${url}`;
  window.open(
    `https://github.com/GoogleCloudPlatform/cicd-foundation/issues/new?body=${encodeURIComponent(
      body,
    )}`,
    "_blank",
  );
}
