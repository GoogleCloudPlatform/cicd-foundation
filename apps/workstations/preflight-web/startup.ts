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
  copySettingsUrl,
  loadConfig,
  reportBug,
  resetConfig,
  saveConfig,
  toggleRetry,
  updateConfig,
  updateStatusMessage,
  updateUIFromConfig,
} from "./config_module";
import {
  checkHealth,
  handleHealthSuccess,
  manualConnect,
  startHealthChecks,
  updateDebugInfo,
  updateTimer,
  updateVisualProgress,
} from "./health_module";
import {
  applyTranslations,
  fetchTranslations,
  filterLanguages,
  loadLocaleHashes,
  renderLanguageList,
  t,
} from "./i18n_module";
import {
  backToComponentDetails,
  backToLicenseList,
  loadSBOM,
  viewFullLicenseText,
} from "./sbom_module";
import { initGlobalShortcuts } from "./shortcuts_module";
import { logInfo, state, updateState } from "./types";
import {
  closeAllModals,
  closeModal,
  initEventListeners,
  openModal,
  renderConnectionTypeList,
  resetUIVisuals,
  syncRetryIntervalState,
  updateDisplayData,
} from "./ui_module";

/**
 * Toggles the visibility of the technical debug overlay.
 */
function toggleDebug(): void {
  updateState({
    config: { ...state.config, showDebug: !state.config.showDebug },
  });
  saveConfig();
  const debugInfo = document.getElementById("debug-container");
  if (debugInfo) {
    debugInfo.classList.toggle("hidden", !state.config.showDebug);
    updateDebugInfo();
  }
  const cb = document.getElementById("debug-enable");
  if (cb instanceof HTMLInputElement) {
    cb.checked = state.config.showDebug;
  }
}

// Global Window API for DOM-based triggers
window.openModal = openModal;
window.closeModal = closeModal;
window.closeAllModals = closeAllModals;
window.toggleRetry = toggleRetry;
window.toggleDebug = toggleDebug;
window.updateConfig = updateConfig;
window.resetConfig = resetConfig;
window.copySettingsUrl = copySettingsUrl;
window.backToLicenseList = backToLicenseList;
window.backToComponentDetails = backToComponentDetails;
window.viewFullLicenseText = (name: string): void => {
  void viewFullLicenseText(name);
};
window.filterLanguages = filterLanguages;
window.reportBug = reportBug;
window.manualConnect = manualConnect;
window.applyTranslations = applyTranslations;
window.updateUIFromConfig = updateUIFromConfig;
window.updateDebugInfo = updateDebugInfo;
window.updateStatusMessage = updateStatusMessage;
window.startHealthChecks = startHealthChecks;
window.updateTimer = updateTimer;
window.handleHealthSuccess = handleHealthSuccess;
window.checkHealth = checkHealth;
window.saveConfig = saveConfig;
window.t = t;
window.fetchTranslations = fetchTranslations;
window.loadLocaleHashes = loadLocaleHashes;
window.loadSBOM = loadSBOM;
window.renderLanguageList = renderLanguageList;
window.renderConnectionTypeList = renderConnectionTypeList;
window.updateDisplayData = updateDisplayData;
window.resetUIVisuals = resetUIVisuals;
window.syncRetryIntervalState = syncRetryIntervalState;

/**
 * Orchestrates the full initialization sequence of the Preflight UI.
 * Ensures the cinematic reveal occurs quickly regardless of technical background processing.
 */
async function initialize(): Promise<void> {
  logInfo("Initializing Preflight UI...");

  const wrapper = document.getElementById("ui-wrapper");
  const bgImg = document.getElementById("background-img");

  const performReveal = (): void => {
    logInfo("Executing UI Reveal...");
    if (bgImg instanceof HTMLImageElement) {
      bgImg.classList.remove("backdrop-blur-3xl", "opacity-0", "scale-105");
      bgImg.style.opacity = "1";
    }
    if (wrapper) {
      wrapper.classList.remove("opacity-0");
      wrapper.classList.add("opacity-100");
    }
  };

  initEventListeners();

  // Fast-path for cached backgrounds
  if (bgImg instanceof HTMLImageElement && bgImg.complete) {
    performReveal();
  } else if (bgImg instanceof HTMLImageElement) {
    bgImg.addEventListener("load", performReveal);
    bgImg.addEventListener("error", performReveal);
    setTimeout(performReveal, 1500);
  } else {
    performReveal();
  }

  try {
    await loadLocaleHashes();
    loadConfig();

    // Core Translation Hydration
    await fetchTranslations("en");
    if (state.config.lang !== "en") {
      try {
        await fetchTranslations(state.config.lang);
      } catch (e) {
        console.warn(`Fallback to English for ${state.config.lang}`);
      }
    }

    // Dynamic Component Rendering
    updateUIFromConfig();
    updateDisplayData();
    updateDebugInfo();
    renderLanguageList();
    renderConnectionTypeList();
    applyTranslations();

    // Orchestration Services
    initGlobalShortcuts();
    startHealthChecks();
    requestAnimationFrame(updateVisualProgress);
    void loadSBOM();
  } catch (e) {
    console.error("initialization failure", e);
    performReveal();
  }

  // Start the high-frequency UI timer
  updateTimer();
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () => {
    void initialize();
  });
} else {
  void initialize();
}

export {};
