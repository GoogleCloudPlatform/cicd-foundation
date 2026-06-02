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
  openModal,
  closeModal,
  renderConnectionTypeList,
  updateDisplayData,
  initEventListeners,
  resetUIVisuals,
  closeAllModals,
  syncRetryIntervalState,
} from "../ui_module";

(global as any).SVGCircleElement = class SVGCircleElement {
  style = { strokeDashoffset: "" };
};

describe("UI Module", () => {
  beforeEach(() => {
    setupMockDOM();
    state.config = { ...DEFAULT_CONFIG, connectionTypes: ["RDP", "SSH"] };
    state.isHealthy = false;

    // Mock global functions
    window.saveConfig = vi.fn();
    window.closeModal = vi.fn();
  });

  test("openModal reveals element", () => {
    const modal = document.getElementById("settings-modal")!;
    openModal("settings-modal");
    expect(modal.classList.contains("hidden")).toBe(false);
  });

  test("closeModal hides element", () => {
    const modal = document.getElementById("settings-modal")!;
    modal.classList.remove("hidden");
    closeModal("settings-modal");
    expect(modal.classList.contains("hidden")).toBe(true);
  });

  test("renderConnectionTypeList generates protocol buttons", () => {
    const list = document.getElementById("connection-type-list")!;
    renderConnectionTypeList();
    expect(list.innerHTML).toContain("Remote Desktop Protocol (RDP)");
    expect(list.innerHTML).toContain("Secure Shell (SSH)");
  });

  test("Desktop icon click triggers manual connect", () => {
    state.isHealthy = true;

    // Wire global mock onto window
    const manualConnectMock = vi.fn();
    window.manualConnect = manualConnectMock;

    initEventListeners();

    const desktopBtn = document.getElementById("desktop-icon-trigger");
    desktopBtn?.click();
    expect(manualConnectMock).toHaveBeenCalled();
  });

  test("updateDisplayData populates text elements", () => {
    state.config = {
      ...state.config,
      hostname: "test-host",
      uplink: "test-uplink",
    };
    updateDisplayData();
    expect(document.getElementById("display-hostname")?.textContent).toBe(
      "test-host",
    );
    expect(document.getElementById("display-uplink")?.textContent).toBe("RDP");
  });

  test("syncAdvancedSections toggles exclusively", () => {
    initEventListeners();
    const basic = document.getElementById(
      "basic-settings-details",
    ) as HTMLDetailsElement;
    const advanced = document.getElementById(
      "advanced-settings-details",
    ) as HTMLDetailsElement;

    basic.open = true;
    advanced.open = true;

    basic.dispatchEvent(new Event("toggle"));
    expect(advanced.open).toBe(false);

    basic.open = false;
    advanced.open = true;
    advanced.dispatchEvent(new Event("toggle"));
    expect(basic.open).toBe(false);
  });

  test("resetUIVisuals resets ring svg transition", () => {
    const svg = document.createElement("div");
    vi.spyOn(document, "querySelector").mockImplementation((sel) => {
      if (sel === "main svg") return svg;
      return null;
    });

    resetUIVisuals();
    expect(svg.style.transition).toBe("none");
    expect(svg.style.opacity).toBe("1");
  });

  test("renderConnectionTypeList handles missing container and button click", () => {
    document.getElementById("connection-type-list")?.remove();
    renderConnectionTypeList();

    setupMockDOM();
    renderConnectionTypeList();
    const btn = document
      .getElementById("connection-type-list")
      ?.querySelector("button") as HTMLButtonElement;
    btn.click();
    expect(state.config.connectionId).toBe("RDP");
  });

  test("Global keyboard listener handles space key in settings modal", () => {
    state.isHealthy = false;
    state.currentModal = "settings-modal";

    const event = new KeyboardEvent("keydown", {
      key: " ",
      cancelable: true,
      bubbles: true,
    });
    Object.defineProperty(event, "target", { value: document.body });
    document.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
  });
  test("openPrivacyModal via click", async () => {
    document.body.innerHTML =
      '<div id="privacy-text-content"></div><div id="privacy-modal"></div><button id="btn-open-privacy-from-help"></button>';
    initEventListeners();

    window.fetch = vi
      .fn()
      .mockResolvedValue({ ok: true, text: async () => "privacy" });
    document.getElementById("btn-open-privacy-from-help")?.click();
    await Promise.resolve();
    await Promise.resolve();

    window.fetch = vi.fn().mockResolvedValue({ ok: false });
    document.getElementById("btn-open-privacy-from-help")?.click();
    await Promise.resolve();
    await Promise.resolve();

    window.fetch = vi.fn().mockRejectedValue(new Error("err"));
    document.getElementById("btn-open-privacy-from-help")?.click();
    await Promise.resolve();
    await Promise.resolve();
  });
  test("openModal switches modal", () => {
    document.body.innerHTML = '<div id="m1"></div><div id="m2"></div>';
    openModal("m1");
    openModal("m2");
  });
  test("openModal specific modals", () => {
    document.body.innerHTML =
      '<div id="license-modal"></div><div id="license-content"></div><div id="license-list-container"></div><div id="component-details"></div><div id="license-viewer"></div><div id="language-modal"></div><input id="language-search"/><div id="shortcuts-modal"></div><input id="shortcut-search"/>';
    openModal("license-modal");
    openModal("language-modal");
    openModal("shortcuts-modal");
  });
  test("syncAdvancedSections branches", () => {
    document.body.innerHTML =
      '<details id="basic-settings-details"></details><details id="advanced-settings-details"></details>';

    const basic = document.getElementById(
      "basic-settings-details",
    ) as HTMLDetailsElement;
    const adv = document.getElementById(
      "advanced-settings-details",
    ) as HTMLDetailsElement;

    // Open basic => closes advanced
    adv.open = true;
    basic.open = true;
    basic.dispatchEvent(new Event("toggle"));

    // Open advanced => closes basic
    adv.open = true;
    basic.open = true;
    adv.dispatchEvent(new Event("toggle"));

    // Close basic => does nothing to adv
    adv.open = true;
    basic.open = false;
    basic.dispatchEvent(new Event("toggle"));

    // Missing elements
    document.body.innerHTML = '<details id="basic-settings-details"></details>';
    document
      .getElementById("basic-settings-details")
      ?.dispatchEvent(new Event("toggle"));
  });
  test("closeModal handles settings-modal", () => {
    document.body.innerHTML = '<div id="settings-modal"></div>';
    state.currentModal = "settings-modal";
    state.previousModal = "other-modal";
    state.uiTransient = {} as any;
    closeModal("settings-modal");
  });
  test("closeAllModals", () => {
    document.body.innerHTML =
      '<div id="m1"></div><div id="settings-modal"></div>';
    state.currentModal = "m1";
    closeAllModals();
    state.currentModal = "settings-modal";
    closeAllModals();
  });
  test("updateDisplayData branches", () => {
    document.body.innerHTML =
      '<div id="display-hostname"></div><div id="display-uplink"></div>';
    updateDisplayData();
  });
  test("resetUIVisuals branches", () => {
    document.body.innerHTML =
      '<div id="status-icon" class="animate-ready"></div><main><svg></svg></main><div class="starfield-container animate-drift"></div><div id="main-status"></div><div id="live-timer"></div>';
    window.applyTranslations = vi.fn();
    resetUIVisuals();
    expect(window.applyTranslations).toHaveBeenCalled();
  });
  test("renderConnectionTypeList coverage", () => {
    document.body.innerHTML = '<div id="connection-type-list"></div>';
    renderConnectionTypeList();
    const btn = document.querySelector(
      "#connection-type-list button",
    ) as HTMLButtonElement;
    btn?.click();
  });
  test("initEventListeners keyboard coverage", () => {
    document.body.innerHTML = `
        <button id="btn-close-settings"></button>
        <button id="btn-open-settings"></button>
        <button id="btn-open-licenses-from-help"></button>
        <button id="btn-update-config"></button>
        <button id="desktop-icon-trigger"></button>
        <input id="language-search"/>
        <textarea id="txt"></textarea>
        <input id="retry-enable" type="checkbox"/>
        <input id="retry-interval" value="50"/>
        <span id="retry-value"></span>
        <input id="timeout-limit" value="50"/>
        <span id="timeout-value"></span>
        <input id="simulate-sec" value="5"/>
        <span id="simulate-value"></span>
        <button id="btn-open-settings-timer"></button>
        <button id="btn-open-settings-uplink"></button>
        <button id="btn-settings-open-language"></button>
        <button id="btn-open-shortcuts-from-help"></button>
        <button id="btn-reset-config"></button>
        <button id="btn-copy-settings-url"></button>
        <button id="btn-report-bug"></button>
        <button id="btn-retry-toggle"></button>
        <button id="btn-manual-connect"></button>
        <button id="btn-manual-connect-msg"></button>
        <button id="back-to-details-btn"></button>
        <button id="btn-close-language"></button>
        <button id="btn-close-license"></button>
        <button id="btn-close-licenses-top"></button>
        <button id="btn-close-shortcuts"></button>
        <button id="btn-close-help"></button>
        <button id="btn-close-privacy"></button>
      `;
    initEventListeners();

    document.getElementById("btn-close-settings")?.click();
    document.getElementById("btn-close-language")?.click();
    document.getElementById("btn-close-license")?.click();
    document.getElementById("btn-close-licenses-top")?.click();
    document.getElementById("back-to-details-btn")?.click();
    document.getElementById("btn-close-shortcuts")?.click();
    document.getElementById("btn-close-help")?.click();
    document.getElementById("btn-close-privacy")?.click();

    document.getElementById("btn-open-settings")?.click();
    document.getElementById("btn-open-settings-timer")?.click();
    document.getElementById("btn-open-settings-uplink")?.click();
    document.getElementById("btn-settings-open-language")?.click();
    document.getElementById("btn-open-shortcuts-from-help")?.click();
    document.getElementById("btn-reset-config")?.click();
    document.getElementById("btn-copy-settings-url")?.click();
    document.getElementById("btn-report-bug")?.click();
    document.getElementById("btn-retry-toggle")?.click();
    document.getElementById("btn-manual-connect")?.click();
    document.getElementById("btn-manual-connect-msg")?.click();

    const retryInterval = document.getElementById("retry-interval");
    retryInterval?.dispatchEvent(new Event("input"));

    const timeoutLimit = document.getElementById("timeout-limit");
    timeoutLimit?.dispatchEvent(new Event("input"));

    const simulateSec = document.getElementById("simulate-sec");
    simulateSec?.dispatchEvent(new Event("input"));

    state.isHealthy = true;
    state.currentModal = null;
    window.manualConnect = vi.fn();
    document.body.dispatchEvent(
      new KeyboardEvent("keydown", { key: "Enter", bubbles: true }),
    );
    expect(window.manualConnect).toHaveBeenCalled();

    document.body.dispatchEvent(
      new KeyboardEvent("keydown", { key: " ", bubbles: true }),
    );

    const search = document.getElementById("language-search");
    if (search) {
      search.dispatchEvent(
        new KeyboardEvent("keydown", { key: "Enter", bubbles: true }),
      );
    }

    const txt = document.getElementById("txt");
    if (txt) {
      txt.dispatchEvent(
        new KeyboardEvent("keydown", { key: "Enter", bubbles: true }),
      );
    }

    state.isHealthy = false;
    state.currentModal = "settings-modal";
    document.body.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));
    document.body.dispatchEvent(new KeyboardEvent("keydown", { key: " " }));
  });
  test("ui_module syncRetryIntervalState missing elements", () => {
    document.body.innerHTML = '<input id="retry-enable" type="checkbox" />';
    syncRetryIntervalState(); // returns early because intervalInput missing
    document.body.innerHTML =
      '<input id="retry-enable" type="checkbox" /><input id="retry-interval" />';
    syncRetryIntervalState(); // returns early because intervalGroup missing
  });
  test("ui_module syncAdvancedSections missing elements via event listener", () => {
    initEventListeners();
    document.body.innerHTML = '<details id="basic-settings-details"></details>';
    const basic = document.getElementById(
      "basic-settings-details",
    ) as HTMLDetailsElement;
    basic.open = true;
    basic.dispatchEvent(new Event("toggle"));
  });
  test("Requirement: Retry Interval is disabled when Auto-Redirect is unchecked", () => {
    initEventListeners();
    const redirectCb = document.getElementById(
      "retry-enable",
    ) as HTMLInputElement;
    const intervalInput = document.getElementById(
      "retry-interval",
    ) as HTMLInputElement;

    openModal("settings-modal");

    redirectCb.checked = false;
    redirectCb.dispatchEvent(new Event("change"));
    expect(intervalInput.disabled).toBe(true);

    redirectCb.checked = true;
    redirectCb.dispatchEvent(new Event("change"));
    expect(intervalInput.disabled).toBe(false);
  });
  test("Requirement: Closing nested Language modal returns to Settings", () => {
    openModal("settings-modal");
    openModal("language-modal");
    expect(state.currentModal).toBe("language-modal");

    closeModal("language-modal");
    expect(state.currentModal).toBe("settings-modal");
  });
});
