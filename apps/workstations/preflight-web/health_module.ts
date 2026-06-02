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

import {
  APP_STATUS_HEADER,
  APP_STATUS_STARTING,
  getGuacamoleUrl,
  MAX_BACKOFF_INTERVAL_MS,
  PROGRESS_RING_CIRCUMFERENCE,
} from "./constants";
import { logInfo, state, updateState } from "./types";
import { windowUtils } from "./window_utils";

/**
 * Executes a single health probe against the workstation backend.
 * Manages the transition between Nominal and Timeout phases.
 */
export async function checkHealth(): Promise<void> {
  const elapsedMs = Date.now() - state.startTime;

  if (elapsedMs > state.config.timeoutMs) {
    handleHealthTimeout();
  }

  // Latency Simulation Path
  if (state.simulateSec > 0) {
    const elapsed = Math.floor(elapsedMs / 1000);
    const remaining = state.simulateSec - elapsed;
    if (remaining > 0) {
      updateDebugInfo();
      return;
    }
  }

  const startTime = performance.now();
  updateState({ pollCount: state.pollCount + 1 });
  try {
    const response = await fetch("/healthz");
    updateState({
      latencyMs: Math.round(performance.now() - startTime),
      lastStatus: response.headers.get(APP_STATUS_HEADER),
    });
    updateDebugInfo();

    if (response.ok && state.lastStatus !== APP_STATUS_STARTING) {
      handleHealthSuccess();
    }
  } catch (e) {
    updateState({
      latencyMs: null,
      lastStatus: "OFFLINE",
    });
    updateDebugInfo();
  }
}

/**
 * High-performance animation loop for the primary progress ring.
 */
export function updateVisualProgress(): void {
  if (state.isHealthy) return;
  const ringPath = document.getElementById("progress-ring-path");
  if (!(ringPath instanceof SVGCircleElement)) return;

  const elapsedMs = Date.now() - state.startTime;
  const progress = Math.min(elapsedMs / state.config.timeoutMs, 1);
  const offset = PROGRESS_RING_CIRCUMFERENCE * (1 - progress);
  ringPath.style.strokeDashoffset = offset.toString();
  requestAnimationFrame(updateVisualProgress);
}

/**
 * Refreshes the technical telemetry data in the debug overlay.
 */
export function updateDebugInfo(): void {
  const container = document.getElementById("debug-container");
  const contentEl = document.getElementById("debug-info-content");
  if (!container || !contentEl) return;

  container.classList.toggle("hidden", !state.config.showDebug);

  const translate = (key: string, def: string): string =>
    window.t?.(key, def) || def;

  const unitMs = translate("label_debug_unit_ms", "ms");
  const unitS = translate("label_debug_unit_s", "s");
  const waitingText = translate("label_debug_waiting", "WAITING");
  const offlineText = translate("label_debug_offline", "OFFLINE");

  const latency =
    state.latencyMs !== null ? `${state.latencyMs}${unitMs}` : "---";
  const elapsed = Math.floor((Date.now() - state.startTime) / 1000);

  let statusDisplay = state.lastStatus || waitingText;
  if (statusDisplay === "OFFLINE") {
    statusDisplay = offlineText;
  }
  if (statusDisplay === APP_STATUS_STARTING) {
    statusDisplay = translate("status_starting", APP_STATUS_STARTING);
  } else if (state.isHealthy) {
    statusDisplay = translate("status_ready", "READY");
  }

  const ua = navigator.userAgent;
  let clientStr = "Unknown";
  if (ua.includes("Chrome")) {
    clientStr = "Chrome";
  } else if (ua.includes("Firefox")) {
    clientStr = "Firefox";
  } else if (ua.includes("Safari")) {
    clientStr = "Safari";
  }

  contentEl.innerHTML = `
    <div class="flex flex-col gap-1.5 uppercase">
      <div class="flex justify-between gap-6"><span>${translate(
        "label_debug_latency",
        "Latency",
      )}</span> <span class="text-secondary">${latency}</span></div>
      <div class="flex justify-between gap-6"><span>${translate(
        "label_debug_elapsed",
        "Elapsed",
      )}</span> <span class="text-secondary">${elapsed}${unitS}</span></div>
      <div class="flex justify-between gap-6"><span>${translate(
        "label_debug_polls",
        "Polls",
      )}</span> <span class="text-secondary">${state.pollCount}</span></div>
      <div class="flex justify-between gap-6"><span>${translate(
        "label_debug_backend",
        "Backend",
      )}</span> <span class="text-secondary truncate max-w-[80px]">${statusDisplay}</span></div>
      <div class="border-t border-white/5 my-0.5"></div>
      <div class="flex justify-between gap-6"><span>${translate(
        "label_debug_auto_redirect",
        "Auto Redirect",
      )}</span> <span class="text-secondary">${
        state.config.autoRedirect
      }</span></div>
      <div class="flex justify-between gap-6"><span>${translate(
        "label_debug_timeout",
        "Timeout",
      )}</span> <span class="text-secondary">${Math.floor(
        state.config.timeoutMs / 1000,
      )}${unitS}</span></div>
      <div class="flex justify-between gap-6"><span>${translate(
        "label_debug_retry_interval",
        "Retry Interval",
      )}</span> <span class="text-secondary">${
        state.config.retryIntervalMs
      }${unitMs}</span></div>
      <div class="flex justify-between gap-6"><span>${translate(
        "label_debug_backoff",
        "Next Poll Delay",
      )}</span> <span class="text-secondary">${Math.round(
        state.currentInterval,
      )}${unitMs}</span></div>
      <div class="flex justify-between gap-6"><span>${translate(
        "label_debug_simulation",
        "Simulation Delay",
      )}</span> <span class="text-secondary">${
        state.simulateSec
      }${unitS}</span></div>
      <div class="border-t border-white/5 my-0.5"></div>
      <div class="flex justify-between gap-6"><span>${translate(
        "label_debug_protocol",
        "Protocol",
      )}</span> <span class="text-secondary">${
        state.config.connectionId
      }</span></div>
      <div class="flex justify-between gap-6"><span>${translate(
        "label_debug_lang",
        "Language",
      )}</span> <span class="text-secondary uppercase">${
        state.config.lang
      }</span></div>
      <div class="flex justify-between gap-6"><span>${translate(
        "label_debug_browser",
        "Browser",
      )}</span> <span class="text-secondary">${clientStr}</span></div>
    </div>
  `;
}

/**
 * Updates the UI state when the nominal startup period is exceeded.
 */
export function handleHealthTimeout(): void {
  const statusEl = document.getElementById("status-message");
  if (
    statusEl &&
    statusEl.getAttribute("data-i18n") !== "status_message_timeout"
  ) {
    statusEl.setAttribute("data-i18n", "status_message_timeout");
    window.applyTranslations?.();
  }
}

/**
 * Transitions the UI to the "READY" state and optionally triggers redirection.
 */
export function handleHealthSuccess(): void {
  if (state.isHealthy) return;
  updateState({ isHealthy: true });
  logInfo("Connection healthy.");

  if (state.checkInterval) {
    clearTimeout(state.checkInterval);
    updateState({ checkInterval: null });
  }

  const statusEl = document.getElementById("status-message");
  if (statusEl) {
    statusEl.setAttribute("data-i18n", "status_message_ready");
  }

  const mainStatus = document.getElementById("main-status");
  if (mainStatus) {
    mainStatus.setAttribute("data-i18n", "status_ready");
  }

  const statusIcon = document.getElementById("status-icon");
  if (statusIcon) {
    statusIcon.classList.add("animate-ready");
  }

  const ringSvg = document.querySelector("main svg");
  if (ringSvg instanceof HTMLElement) {
    ringSvg.style.transition = "opacity 500ms ease-out";
    ringSvg.style.opacity = "0";
  }

  const starfield = document.querySelector(".starfield-container");
  if (starfield) {
    starfield.classList.remove("animate-drift");
  }

  window.applyTranslations?.();
  window.updateUIFromConfig?.();
  window.updateDebugInfo?.();

  if (state.config.autoRedirect && !state.currentModal) {
    startRedirect();
  }
}

/**
 * Initiates the recursive health monitoring loop.
 */
export function startHealthChecks(): void {
  if (state.checkInterval) {
    clearTimeout(state.checkInterval);
  }
  updateState({ currentInterval: state.config.retryIntervalMs });

  const poll = async (): Promise<void> => {
    if (state.isHealthy) return;
    await checkHealth();

    if (!state.isHealthy) {
      const elapsedMs = Date.now() - state.startTime;
      let newInterval = state.config.retryIntervalMs;
      if (elapsedMs > state.config.timeoutMs) {
        newInterval = Math.min(
          state.currentInterval * 1.5,
          MAX_BACKOFF_INTERVAL_MS,
        );
      }
      updateState({ currentInterval: newInterval });

      const jitter = Math.random() * 200;
      updateDebugInfo();
      updateState({
        checkInterval: window.setTimeout(() => {
          void poll();
        }, state.currentInterval + jitter),
      });
    }
  };
  void poll();
}

/**
 * Global UI timer for the primary dashboard. Updates the elapsed time display and checks for timeouts.
 */
export function updateTimer(): void {
  if (state.isHealthy) return;
  const elapsedMs = Date.now() - state.startTime;
  const elapsedSec = Math.floor(elapsedMs / 1000);

  const timerEl = document.getElementById("live-timer");
  if (timerEl) {
    const mins = Math.floor(elapsedSec / 60);
    const secs = elapsedSec % 60;
    timerEl.textContent = `${mins.toString().padStart(2, "0")}:${secs
      .toString()
      .padStart(2, "0")}`;
  }

  if (elapsedMs > state.config.timeoutMs) {
    handleHealthTimeout();
  }

  if (state.simulateSec > 0) {
    window.applyTranslations?.();
  }
  updateState({
    timerInterval: window.setTimeout(updateTimer, 1000),
  });
}

/**
 * Manually triggers a redirection to the workstation backend.
 */
export function manualConnect(): void {
  startRedirect();
}

/**
 * Assigns the browser location to the specific protocol path or root fallback.
 */
export function startRedirect(): void {
  const protocol = state.config.connectionId;
  const targetUrl = protocol ? getGuacamoleUrl(protocol) : "/";
  windowUtils.assign(targetUrl);
}
