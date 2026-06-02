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
import { setupMockDOM, MOCK_TRANSLATIONS } from "./helpers";
import {
  applyTranslations,
  renderLanguageList,
  loadLocaleHashes,
  fetchTranslations,
  t,
  setLanguage,
  filterLanguages,
  SUPPORTED_LANGS,
} from "../i18n_module";
import { updateStatusMessage } from "../config_module";
import { openModal } from "../ui_module";

describe("i18n Module", () => {
  beforeEach(() => {
    setupMockDOM();
    state.config = { ...state.config, lang: "en" };
    state.translations["en"] = {
      name: "English",
      native: "English",
      dict: MOCK_TRANSLATIONS,
    };

    // Mock translate function
    window.t = (key: string, def: string): string => {
      const lang = state.config.lang || "en";
      const set = state.translations[lang];
      return (set && set.dict[key]) || def;
    };
  });

  test("applyTranslations updates DOM content", () => {
    applyTranslations();
    const status = document.getElementById("main-status");
    expect(status?.textContent).toBe("STARTING");
  });

  test("renderLanguageList populates container and handles filtering", () => {
    const list = document.getElementById("language-list")!;

    // Initial render
    renderLanguageList();
    expect(list.children.length).toBeGreaterThan(0);
    expect(list.innerHTML).toContain("English");
    expect(list.innerHTML).toContain("Français");

    // Filtered render
    renderLanguageList("eng");
    expect(list.innerHTML).toContain("English");
    expect(list.innerHTML).not.toContain("Français");
  });

  test("Space key toggle respects selected language translations", () => {
    const msgEl = document.getElementById("status-message")!;
    state.config = { ...state.config, lang: "fr" };
    state.translations["fr"] = {
      name: "French",
      native: "Français",
      dict: {
        status_message: "FR_WAIT",
        status_message_manual: "FR_MANUAL",
      },
    };

    state.config = { ...state.config, autoRedirect: true };
    updateStatusMessage();
    expect(msgEl.textContent).toBe("FR_WAIT");

    state.config = { ...state.config, autoRedirect: false };
    updateStatusMessage();
    expect(msgEl.textContent).toBe("FR_MANUAL");
  });

  test("t() falls back if key or set is missing", () => {
    state.config = { ...state.config, lang: "unknown" };
    expect(window.t?.("any", "fallback")).toBe("fallback");

    state.config = { ...state.config, lang: "en" };
    expect(window.t?.("missing_key", "fallback")).toBe("fallback");
  });

  test("applyTranslations handles missing attributes and translations", () => {
    const div = document.createElement("div");
    div.setAttribute("data-i18n", "");
    document.body.appendChild(div);

    state.translations["en"] = { ...state.translations["en"], dict: {} };
    const status = document.createElement("div");
    status.id = "main-status";
    status.setAttribute("data-i18n", "status_starting");
    document.body.appendChild(status);

    const missingEl = document.createElement("div");
    missingEl.setAttribute("data-i18n", "missing_key");
    document.body.appendChild(missingEl);

    state.isHealthy = true;
    applyTranslations();

    expect(status.textContent).toBe("READY");
    expect(missingEl.textContent).toBe("");
  });

  test("renderLanguageList handles null container and button click", () => {
    document.getElementById("language-list")?.remove();
    renderLanguageList();

    setupMockDOM();
    renderLanguageList();
    const btn = document.querySelector(
      "#language-list button",
    ) as HTMLButtonElement;

    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({}),
    }) as any;

    btn.click();
    expect(global.fetch).toHaveBeenCalled();
  });
  test("loadLocaleHashes ok", async () => {
    window.fetch = vi
      .fn()
      .mockResolvedValue({ ok: true, json: async () => ({}) });
    await loadLocaleHashes();
  });
  test("loadLocaleHashes err", async () => {
    window.fetch = vi.fn().mockRejectedValue(new Error("err"));
    await loadLocaleHashes();
  });
  test("fetchTranslations ok", async () => {
    window.fetch = vi
      .fn()
      .mockResolvedValue({ ok: true, json: async () => ({}) });
    await fetchTranslations("es");
    await fetchTranslations("es"); // skip already fetched
  });
  test("fetchTranslations err", async () => {
    window.fetch = vi.fn().mockRejectedValue(new Error("err"));
    await fetchTranslations("de");
  });
  test("t key fallback", () => {
    state.translations["en"] = { name: "en", native: "en", dict: { a: "b" } };
    state.translations["fr"] = { name: "fr", native: "fr", dict: { c: "d" } };
    state.config = { ...state.config, lang: "fr" };
    expect(t("a", "x")).toBe("x"); // missing key in current lang, fallback string
    expect(t("c", "x")).toBe("d");

    state.config = { ...state.config, lang: "it" }; // missing lang entirely
    expect(t("a", "x")).toBe("b"); // fallback to 'en' dict
    expect(t("nonexistent", "x")).toBe("x");
  });
  test("applyTranslations branches", () => {
    document.body.innerHTML = `
        <div data-i18n="status_starting"></div>
        <div data-i18n="other"></div>
        <div data-i18n-aria="key"></div>
        <div data-i18n-title="key"></div>
        <div data-i18n-placeholder="key"></div>
        <div id="main-status" class="animate-cosmic-pulse animate-glow"></div>
      `;
    state.translations["en"] = {
      name: "en",
      native: "en",
      dict: { key: "val", status_ready: "R", other: "O" },
    };
    state.config = { ...state.config, lang: "en" };

    state.isHealthy = false;
    applyTranslations();

    state.isHealthy = true;
    applyTranslations();

    // without set dict
    state.translations = {};
    applyTranslations();
  });
  test("setLanguage", async () => {
    document.body.innerHTML = '<div id="display-active-lang"></div>';
    window.fetch = vi
      .fn()
      .mockResolvedValue({ ok: true, json: async () => ({}) });
    await setLanguage("en");
    await setLanguage("nonexistent");
  });
  test("filterLanguages", () => {
    document.body.innerHTML =
      '<input id="language-search" value="eng"/><div id="language-list"></div>';
    filterLanguages();
  });
  test("renderLanguageList filter hits", () => {
    document.body.innerHTML = '<div id="language-list"></div>';
    renderLanguageList("english");
    renderLanguageList("nonexistent");
  });
  test("i18n_module applyTranslations missing key", () => {
    document.body.innerHTML = `
      <div data-i18n="missing_key"></div>
      <div data-i18n-aria="missing_key"></div>
      <div data-i18n-title="missing_key"></div>
      <div data-i18n-placeholder="missing_key"></div>
    `;
    applyTranslations();
  });
  test("i18n_module applyTranslations state.isHealthy", () => {
    state.isHealthy = true;
    document.body.innerHTML = `
      <div data-i18n="status_starting"></div>
      <div id="main-status"></div>
    `;
    applyTranslations();
  });
  test("i18n_module filterLanguages handles missing search", () => {
    document.body.innerHTML = "";
    renderLanguageList("filter");
    expect(document.getElementById("language-list")).toBeNull();
  });
  test("filterLanguages missing searchEl", () => {
    document.body.innerHTML = "";
    filterLanguages();
  });
  test("t() falls back if key or set is missing", () => {
    state.config = { ...state.config, lang: "unknown" };
    expect(window.t?.("any", "fallback")).toBe("fallback");
    // also test REAL t
    expect(t("any", "fallback")).toBe("fallback");
  });
  test("applyTranslations missing set", () => {
    state.config = { ...state.config, lang: "unknown" };
    applyTranslations();
  });
  test("renderLanguageList loop branches", () => {
    document.body.innerHTML = '<div id="language-list"></div>';
    (SUPPORTED_LANGS as any)["fake"] = undefined;
    renderLanguageList("fake");
    delete (SUPPORTED_LANGS as any)["fake"];
  });
  test("Requirement: Selecting a language returns to Settings", async () => {
    const { closeModal } = await import("../ui_module");
    window.closeModal = vi.fn((id: string) => closeModal(id));
    openModal("settings-modal");
    openModal("language-modal");

    state.translations["fr"] = { name: "French", native: "Français", dict: {} };

    await setLanguage("fr");
    expect(state.currentModal).toBe("settings-modal");
  });
  test("Requirement: Language sub-label updates dynamically in Settings", async () => {
    const label = document.getElementById("display-active-lang")!;
    state.translations["ar"] = { name: "Arabic", native: "العربية", dict: {} };

    await setLanguage("ar");
    expect(label.textContent).toBe("العربية");
  });
});
