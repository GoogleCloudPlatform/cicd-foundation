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

import { state, updateState } from "./types";

/**
 * Interface for language definition.
 */
interface LanguageDef {
  readonly name: string;
  readonly native: string;
}

/**
 * Supported UI languages and their display names.
 */
export const SUPPORTED_LANGS: Record<string, LanguageDef> = {
  en: { name: "English", native: "English" },
  ar: { name: "Arabic", native: "العربية" },
  zh: { name: "Chinese", native: "中文" },
  fr: { name: "French", native: "Français" },
  ru: { name: "Russian", native: "Русский" },
  es: { name: "Spanish", native: "Español" },
};

/**
 * Loads the pre-calculated Subresource Integrity (SRI) hashes for locale files.
 */
export async function loadLocaleHashes(): Promise<void> {
  try {
    const response = await fetch("/locale-hashes.json");
    if (response.ok) {
      updateState({
        localeHashes: (await response.json()) as Record<string, string>,
      });
    }
  } catch (e) {
    console.error("failed to load locale hashes", e);
  }
}

/**
 * Fetches the translation dictionary for the specified language.
 * @param lang The language code to fetch translations for.
 */
export async function fetchTranslations(lang: string): Promise<void> {
  if (state.translations[lang]) return;
  const filename = `${lang}.json`;
  try {
    const response = await fetch(`/locales/${filename}`);
    if (response.ok) {
      const dict = (await response.json()) as Record<string, string>;
      const langDef = SUPPORTED_LANGS[lang];
      if (langDef) {
        updateState({
          translations: {
            ...state.translations,
            [lang]: {
              ...langDef,
              dict,
            },
          },
        });
      }
    }
  } catch (e) {
    console.error(`failed to load translations for ${lang}`, e);
  }
}

/**
 * Retrieves a translated string by key with a fallback default.
 * @param key The translation key.
 * @param defaultString The fallback string if the key is not found.
 * @returns The translated string or the default string.
 */
export function t(key: string, defaultString: string): string {
  const lang = state.config.lang || "en";
  const set = state.translations[lang] || state.translations["en"];
  return set && set.dict[key] ? set.dict[key] : defaultString;
}

/**
 * Scans the DOM for elements with data-i18n attributes and applies translations.
 * Handles specialized attributes like aria-label, title, and placeholder.
 */
export function applyTranslations(): void {
  const lang = state.config.lang || "en";
  const set = state.translations[lang] || state.translations["en"];
  if (!set) return;

  document.querySelectorAll("[data-i18n]").forEach((el) => {
    const key = el.getAttribute("data-i18n");
    if (!key) return;

    // State-aware dynamic text overrides
    if (key === "status_starting" && state.isHealthy) {
      el.textContent = set.dict["status_ready"] || "READY";
      return;
    }

    const text = set.dict[key];
    if (text) {
      el.textContent = text;
    }
  });

  document.querySelectorAll("[data-i18n-aria]").forEach((el) => {
    const key = el.getAttribute("data-i18n-aria");
    if (key && set.dict[key]) {
      el.setAttribute("aria-label", set.dict[key]);
    }
  });

  document.querySelectorAll("[data-i18n-title]").forEach((el) => {
    const key = el.getAttribute("data-i18n-title");
    if (key && set.dict[key]) {
      el.setAttribute("title", set.dict[key]);
    }
  });

  document.querySelectorAll("[data-i18n-placeholder]").forEach((el) => {
    const key = el.getAttribute("data-i18n-placeholder");
    if (key && set.dict[key]) {
      el.setAttribute("placeholder", set.dict[key]);
    }
  });

  // Visual feedback for primary status text
  const statusEl = document.getElementById("main-status");
  if (statusEl) {
    if (state.isHealthy) {
      statusEl.classList.remove("animate-cosmic-pulse");
      statusEl.classList.add("animate-glow", "text-neutral-300");
    } else {
      statusEl.classList.remove("animate-glow");
      statusEl.classList.add("animate-cosmic-pulse");
    }
  }

  // Set document-level localization metadata
  document.documentElement.lang = lang;
  document.documentElement.dir = ["ar", "he", "fa", "ur"].includes(lang)
    ? "rtl"
    : "ltr";
}

/**
 * Updates the application language and triggers a localized UI refresh.
 * @param lang The language code to switch to.
 */
export async function setLanguage(lang: string): Promise<void> {
  await fetchTranslations(lang);
  updateState({ config: { ...state.config, lang } });

  const activeLangEl = document.getElementById("display-active-lang");
  if (activeLangEl) {
    const langDef = SUPPORTED_LANGS[lang];
    if (langDef) {
      activeLangEl.textContent = langDef.native;
    }
  }

  applyTranslations();
  window.updateDebugInfo?.();
  renderLanguageList();
  window.closeModal?.("language-modal");
}

/**
 * Filters the language list based on user search input.
 */
export function filterLanguages(): void {
  const searchEl = document.getElementById(
    "language-search",
  ) as HTMLInputElement | null;
  if (!searchEl) return;
  renderLanguageList(searchEl.value.toLowerCase());
}

/**
 * Renders the interactive language selection list.
 * @param filter Optional filter string to narrow down the list.
 */
export function renderLanguageList(filter = ""): void {
  const container = document.getElementById("language-list");
  if (!container) return;
  container.innerHTML = "";
  const sortedCodes = Object.keys(SUPPORTED_LANGS).sort((a, b) => {
    const langA = SUPPORTED_LANGS[a];
    const langB = SUPPORTED_LANGS[b];
    return langA && langB ? langA.name.localeCompare(langB.name) : 0;
  });

  sortedCodes.forEach((code) => {
    const lang = SUPPORTED_LANGS[code];
    if (!lang) return;

    if (
      lang.name.toLowerCase().includes(filter) ||
      lang.native.toLowerCase().includes(filter) ||
      code.includes(filter)
    ) {
      const btn = document.createElement("button");
      const isActive = state.config.lang === code;
      btn.className = `w-full text-start p-4 rounded-lg border transition-all flex items-center justify-between ${
        isActive
          ? "bg-neutral-800 border-secondary text-secondary font-bold"
          : "bg-neutral-900 border-neutral-700 hover:bg-neutral-800 text-on-surface"
      }`;
      btn.onclick = (): void => {
        void setLanguage(code);
      };
      btn.innerHTML = `<div><div class="text-sm">${
        lang.native
      }</div><div class="text-[10px] opacity-60 uppercase tracking-widest">${
        lang.name
      }</div></div>${
        isActive
          ? '<span class="material-symbols-outlined text-sm">check_circle</span>'
          : ""
      }`;
      container.appendChild(btn);
    }
  });
}
