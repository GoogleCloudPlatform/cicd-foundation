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
  applyUIValues,
  clearAllData,
  copySettingsUrl,
  getCurrentUIValues,
  mapStepToRetry,
  mapStepToTimeout,
  toggleRetry,
  updateConfig,
  updateUIFromConfig,
} from "./config_module";
import { getProtocolFullName } from "./constants";
import { filterLanguages } from "./i18n_module";
import { backToComponentDetails, renderLicenseList } from "./sbom_module";
import { filterShortcuts, renderShortcutsList } from "./shortcuts_module";
import { state, updateState } from "./types";

/**
 * Opens a modal by ID and manages the modal history stack.
 * @param id The DOM ID of the modal to open.
 */
export function openModal(id: string): void {
  if (state.currentModal && state.currentModal !== id) {
    if (state.currentModal === "settings-modal") {
      updateState({ uiTransient: getCurrentUIValues() });
    }
    updateState({ previousModal: state.currentModal });
    const current = document.getElementById(state.currentModal);
    if (current) {
      current.classList.add("hidden");
    }
  } else if (!state.currentModal) {
    updateState({ previousModal: null });
  }

  updateState({ currentModal: id });
  const modal = document.getElementById(id);
  if (modal) {
    modal.classList.remove("hidden");

    if (id === "license-modal") {
      document.getElementById("license-content")?.classList.remove("hidden");
      document
        .getElementById("license-list-container")
        ?.classList.remove("hidden");
      document.getElementById("component-details")?.classList.add("hidden");
      document.getElementById("license-viewer")?.classList.add("hidden");
      renderLicenseList();
    }

    if (id === "language-modal") {
      const search = document.getElementById("language-search");
      if (search instanceof HTMLInputElement) {
        search.value = "";
        search.focus();
        window.renderLanguageList?.();
      }
    } else if (id === "shortcuts-modal") {
      const search = document.getElementById("shortcut-search");
      if (search instanceof HTMLInputElement) {
        search.value = "";
        search.focus();
        renderShortcutsList();
      }
    }
  }
}

/**
 * Fetches and displays the professional HTML documentation fragments for privacy.
 */
async function openPrivacyModal(): Promise<void> {
  const contentEl = document.getElementById("privacy-text-content");
  if (contentEl) {
    const loadingText =
      window.t?.("label_loading_privacy", "Loading Privacy Notice...") ||
      "Loading Privacy Notice...";
    contentEl.innerHTML = `<p class="text-secondary animate-pulse p-8 uppercase tracking-widest text-center">${loadingText}</p>`;
    try {
      const response = await fetch("/privacy_notice.html");
      if (response.ok) {
        contentEl.innerHTML = await response.text();
      } else {
        const errText =
          window.t?.("error_loading_privacy", "error loading privacy notice") ||
          "error loading privacy notice";
        contentEl.innerHTML = `<p class="text-red-400 p-8 text-center uppercase tracking-widest">${errText}</p>`;
      }
    } catch (e) {
      const netErrText =
        window.t?.("error_network", "network error") || "network error";
      contentEl.innerHTML = `<p class="text-red-400 p-8 text-center uppercase tracking-widest">${netErrText}</p>`;
    }
  }
  openModal("privacy-modal");
}

/**
 * Synchronizes the visibility and interactive state of the Retry Interval slider.
 */
export function syncRetryIntervalState(): void {
  if (typeof document === "undefined") return;
  const redirectCb = document.getElementById("retry-enable");
  const intervalInput = document.getElementById("retry-interval");
  const intervalGroup = document.getElementById("retry-interval-group");
  if (
    redirectCb instanceof HTMLInputElement &&
    intervalInput instanceof HTMLInputElement &&
    intervalGroup
  ) {
    const isEnabled = redirectCb.checked;
    intervalInput.disabled = !isEnabled;
    intervalGroup.classList.toggle("opacity-40", !isEnabled);
    intervalGroup.classList.toggle("pointer-events-none", !isEnabled);
  }
}

/**
 * Manages exclusive expansion of Basic vs Advanced settings sections.
 * @param expandedId The ID of the section that was just expanded.
 */
function syncAdvancedSections(
  expandedId: "basic-settings-details" | "advanced-settings-details",
): void {
  if (typeof document === "undefined") return;
  const basic = document.getElementById("basic-settings-details");
  const advanced = document.getElementById("advanced-settings-details");

  if (
    expandedId === "basic-settings-details" &&
    basic instanceof HTMLDetailsElement &&
    basic.open &&
    advanced instanceof HTMLDetailsElement
  ) {
    advanced.open = false;
  } else if (
    expandedId === "advanced-settings-details" &&
    advanced instanceof HTMLDetailsElement &&
    advanced.open &&
    basic instanceof HTMLDetailsElement
  ) {
    basic.open = false;
  }
}

/**
 * Closes a modal and returns to the previous modal if it exists.
 * @param id The DOM ID of the modal to close.
 */
export function closeModal(id: string): void {
  const modal = document.getElementById(id);
  if (modal) {
    modal.classList.add("hidden");
  }

  if (id === "settings-modal") {
    updateUIFromConfig();
    updateState({ uiTransient: null });
  }

  if (state.currentModal === id) {
    if (state.previousModal) {
      const prev = state.previousModal;
      updateState({ previousModal: null, currentModal: null });
      openModal(prev);

      if (prev === "settings-modal") {
        updateUIFromConfig();
        if (state.uiTransient) {
          applyUIValues(state.uiTransient);
        }
        syncRetryIntervalState();
      }
    } else {
      updateState({ currentModal: null });
    }
  }
}

/**
 * Discards all modal state and returns to the dashboard.
 */
export function closeAllModals(): void {
  if (state.currentModal) {
    const modal = document.getElementById(state.currentModal);
    if (modal) {
      modal.classList.add("hidden");
      if (state.currentModal === "settings-modal") {
        updateUIFromConfig();
      }
    }
  }
  updateState({
    currentModal: null,
    previousModal: null,
    uiTransient: null,
  });
}

/**
 * Updates non-form visual metadata (Hostname, Uplink).
 */
export function updateDisplayData(): void {
  const hostEl = document.getElementById("display-hostname");
  if (hostEl) {
    hostEl.textContent = state.config.hostname;
  }
  const uplinkEl = document.getElementById("display-uplink");
  if (uplinkEl) {
    uplinkEl.textContent = state.config.connectionId.toUpperCase();
  }
}

/**
 * Restores the dashboard to its initial "Starting" visual state.
 */
export function resetUIVisuals(): void {
  const statusIcon = document.getElementById("status-icon");
  if (statusIcon) {
    statusIcon.classList.remove("animate-ready");
  }
  const ringSvg = document.querySelector("main svg");
  if (ringSvg instanceof HTMLElement) {
    ringSvg.style.transition = "none";
    ringSvg.style.opacity = "1";
  }
  const starfield = document.querySelector(".starfield-container");
  if (starfield) {
    starfield.classList.add("animate-drift");
  }
  const mainStatus = document.getElementById("main-status");
  if (mainStatus) {
    mainStatus.setAttribute("data-i18n", "status_starting");
  }
  const timerEl = document.getElementById("live-timer");
  if (timerEl) {
    timerEl.textContent = "00:00";
  }
  window.applyTranslations?.();
}

/**
 * Dynamically renders the connection protocol selection list.
 */
export function renderConnectionTypeList(): void {
  const container = document.getElementById("connection-type-list");
  if (!container) return;
  container.innerHTML = "";

  state.config.connectionTypes.forEach((proto) => {
    const btn = document.createElement("button");
    btn.className = `w-full text-left p-3 rounded mb-2 border transition-colors ${
      state.config.connectionId === proto
        ? "bg-secondary/20 border-secondary text-secondary"
        : "bg-white/5 border-neutral-800 text-white hover:bg-white/10"
    }`;
    btn.textContent = getProtocolFullName(proto);
    btn.onclick = (): void => {
      updateState({ config: { ...state.config, connectionId: proto } });
      renderConnectionTypeList();
    };
    container.appendChild(btn);
  });
}

/**
 * Attaches all global event listeners to DOM elements.
 */
export function initEventListeners(): void {
  // Modal Close Buttons
  document
    .getElementById("btn-close-settings")
    ?.addEventListener("click", () => closeModal("settings-modal"));
  document
    .getElementById("btn-close-language")
    ?.addEventListener("click", () => closeModal("language-modal"));
  document
    .getElementById("btn-close-license")
    ?.addEventListener("click", () => closeModal("license-modal"));
  document
    .getElementById("btn-close-licenses-top")
    ?.addEventListener("click", () => closeModal("license-modal"));
  document
    .getElementById("back-to-details-btn")
    ?.addEventListener("click", () => backToComponentDetails());
  document
    .getElementById("btn-close-shortcuts")
    ?.addEventListener("click", () => closeModal("shortcuts-modal"));
  document
    .getElementById("btn-close-help")
    ?.addEventListener("click", () => closeModal("help-modal"));
  document
    .getElementById("btn-close-privacy")
    ?.addEventListener("click", () => closeModal("privacy-modal"));

  // Modal Open Buttons
  document
    .getElementById("btn-open-settings")
    ?.addEventListener("click", () => {
      openModal("settings-modal");
      syncRetryIntervalState();
    });
  document
    .getElementById("btn-open-settings-timer")
    ?.addEventListener("click", () => {
      openModal("settings-modal");
      syncRetryIntervalState();
    });
  document
    .getElementById("btn-open-settings-uplink")
    ?.addEventListener("click", () => {
      openModal("settings-modal");
      syncRetryIntervalState();
    });
  document
    .getElementById("btn-open-language")
    ?.addEventListener("click", () => openModal("language-modal"));
  document
    .getElementById("btn-settings-open-language")
    ?.addEventListener("click", () => openModal("language-modal"));
  document
    .getElementById("btn-open-license")
    ?.addEventListener("click", () => openModal("license-modal"));
  document
    .getElementById("btn-open-shortcuts")
    ?.addEventListener("click", () => openModal("shortcuts-modal"));
  document
    .getElementById("btn-open-help")
    ?.addEventListener("click", () => openModal("help-modal"));

  // Bridge Listeners (Help Modal)
  document
    .getElementById("btn-open-licenses-from-help")
    ?.addEventListener("click", () => openModal("license-modal"));
  document
    .getElementById("btn-open-shortcuts-from-help")
    ?.addEventListener("click", () => openModal("shortcuts-modal"));
  document
    .getElementById("btn-open-privacy-from-help")
    ?.addEventListener("click", () => {
      void openPrivacyModal();
    });

  // Settings Actions
  document
    .getElementById("btn-update-config")
    ?.addEventListener("click", () => {
      updateConfig();
      closeAllModals();
    });
  document
    .getElementById("btn-reset-config")
    ?.addEventListener("click", () => clearAllData());
  document
    .getElementById("btn-copy-settings-url")
    ?.addEventListener("click", () => {
      copySettingsUrl();
    });
  document
    .getElementById("btn-report-bug")
    ?.addEventListener("click", () => window.reportBug?.());
  document
    .getElementById("btn-retry-toggle")
    ?.addEventListener("click", () => toggleRetry());

  // Main Dashboard Interaction
  document
    .getElementById("desktop-icon-trigger")
    ?.addEventListener("click", () => window.manualConnect?.());
  document
    .getElementById("btn-manual-connect")
    ?.addEventListener("click", () => window.manualConnect?.());
  document
    .getElementById("btn-manual-connect-msg")
    ?.addEventListener("click", () => window.manualConnect?.());

  // Search Filters
  document
    .getElementById("language-search")
    ?.addEventListener("input", () => filterLanguages());
  document
    .getElementById("shortcut-search")
    ?.addEventListener("input", () => filterShortcuts());

  // Dynamic UI Sync
  document
    .getElementById("retry-enable")
    ?.addEventListener("change", () => syncRetryIntervalState());
  document
    .getElementById("basic-settings-details")
    ?.addEventListener("toggle", () =>
      syncAdvancedSections("basic-settings-details"),
    );
  document
    .getElementById("advanced-settings-details")
    ?.addEventListener("toggle", () =>
      syncAdvancedSections("advanced-settings-details"),
    );

  // Slider Listeners
  const retryInterval = document.getElementById("retry-interval");
  const retryValue = document.getElementById("retry-value");
  if (retryInterval instanceof HTMLInputElement && retryValue) {
    retryInterval.addEventListener("input", () => {
      const val = mapStepToRetry(parseInt(retryInterval.value, 10));
      retryValue.textContent = `${Math.round(val)}ms`;
    });
  }

  const timeoutLimit = document.getElementById("timeout-limit");
  const timeoutValue = document.getElementById("timeout-value");
  if (timeoutLimit instanceof HTMLInputElement && timeoutValue) {
    timeoutLimit.addEventListener("input", () => {
      const val = mapStepToTimeout(parseInt(timeoutLimit.value, 10));
      timeoutValue.textContent = `${val}s`;
    });
  }

  const simulateSec = document.getElementById("simulate-sec");
  const simulateValue = document.getElementById("simulate-value");
  if (simulateSec instanceof HTMLInputElement && simulateValue) {
    simulateSec.addEventListener("input", () => {
      simulateValue.textContent = `${simulateSec.value}s`;
    });
  }

  // Global Keyboard Listeners
  document.addEventListener("keydown", (e) => {
    if (e.key === "Enter" || e.key === " ") {
      // Avoid triggering when typing in search inputs
      if (
        e.target instanceof HTMLInputElement ||
        e.target instanceof HTMLTextAreaElement
      ) {
        return;
      }

      if (state.isHealthy && !state.currentModal) {
        if (e.key === " ") e.preventDefault();
        window.manualConnect?.();
      } else if (state.currentModal === "settings-modal") {
        if (e.key === " ") e.preventDefault();
        updateConfig();
        closeAllModals();
      }
    }
  });
}
