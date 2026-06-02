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

import { state } from "./types";

/**
 * Definition of a keyboard shortcut and its metadata.
 * Supports multiple trigger keys for a single action.
 */
interface Shortcut {
  readonly keys: ReadonlyArray<string>;
  readonly action: () => void;
  readonly i18nKey: string;
  readonly category: "system" | "navigation" | "debug";
}

/**
 * Registry of global keyboard shortcuts.
 * Uses late-binding via the global window object to avoid circular dependencies.
 * Grouped and sorted for intuitive discovery.
 */
export const shortcuts: ReadonlyArray<Shortcut> = [
  {
    keys: ["H", "?"],
    action: (): void => window.openModal?.("help-modal"),
    i18nKey: "desc_shortcut_help",
    category: "navigation",
  },
  {
    keys: ["S"],
    action: (): void => window.openModal?.("settings-modal"),
    i18nKey: "desc_shortcut_s",
    category: "navigation",
  },
  {
    keys: ["L"],
    action: (): void => window.openModal?.("language-modal"),
    i18nKey: "desc_shortcut_l",
    category: "navigation",
  },
  {
    keys: ["O"],
    action: (): void => window.openModal?.("license-modal"),
    i18nKey: "desc_shortcut_o",
    category: "navigation",
  },
  {
    keys: ["K"],
    action: (): void => window.openModal?.("shortcuts-modal"),
    i18nKey: "desc_shortcut_shortcuts",
    category: "navigation",
  },
  {
    keys: ["Enter"],
    action: (): void => window.manualConnect?.(),
    i18nKey: "desc_shortcut_enter",
    category: "system",
  },
  {
    keys: ["Space"],
    action: (): void => window.toggleRetry?.(),
    i18nKey: "desc_shortcut_space",
    category: "system",
  },
  {
    keys: ["Escape"],
    action: (): void => window.closeAllModals?.(),
    i18nKey: "",
    category: "system",
  },
  {
    keys: ["D"],
    action: (): void => window.toggleDebug?.(),
    i18nKey: "desc_shortcut_debug",
    category: "debug",
  },
  {
    keys: ["B"],
    action: (): void => window.reportBug?.(),
    i18nKey: "desc_shortcut_b",
    category: "debug",
  },
];

/**
 * Attaches the global keyboard event listener.
 * Handles single keys and character aliases.
 * Shortcuts are ignored if a modal is open (except for Escape).
 */
export function initGlobalShortcuts(): void {
  window.addEventListener("keydown", (e: KeyboardEvent) => {
    // Ignore shortcuts if the user is typing in an input or textarea
    const activeEl = document.activeElement;
    if (
      activeEl instanceof HTMLInputElement ||
      activeEl instanceof HTMLTextAreaElement
    ) {
      if (e.key === "Escape") {
        activeEl.blur();
      }
      return;
    }

    const inputKey = e.key === " " ? "SPACE" : e.key.toUpperCase();
    const shortcut = shortcuts.find((s) =>
      s.keys.some((k) => k.toUpperCase() === inputKey),
    );

    if (shortcut) {
      // Logic: Only allow 'Escape' if a modal is open. Others require currentModal to be null.
      const isEscape = shortcut.keys.includes("Escape");
      if (state.currentModal && !isEscape) {
        return;
      }

      e.preventDefault();
      shortcut.action();
    }
  });
}

/**
 * Renders the shortcut documentation list in the UI, grouped by category.
 * Merges aliases (e.g., H / ?) into single line items.
 * @param filter Optional filter string to narrow down the list.
 */
export function renderShortcutsList(filter = ""): void {
  const container = document.getElementById("shortcuts-list-container");
  if (!container) return;

  container.innerHTML = "";
  const filtered = shortcuts.filter(
    (s) =>
      s.i18nKey &&
      (s.keys.some((k) => k.toLowerCase().includes(filter)) ||
        window.t?.(s.i18nKey, "").toLowerCase().includes(filter)),
  );

  const categories: Record<string, Shortcut[]> = {};
  filtered.forEach((s) => {
    if (!categories[s.category]) {
      categories[s.category] = [];
    }
    categories[s.category].push(s);
  });

  const order: Array<Shortcut["category"]> = ["system", "navigation", "debug"];
  order.forEach((cat) => {
    const shortcutList = categories[cat];
    if (!shortcutList) return;

    const section = document.createElement("div");
    section.className = "col-span-full mb-8";
    section.innerHTML = `
      <h3 class="ui-label mb-3 text-secondary opacity-80 border-b border-white/5 pb-2">${cat.toUpperCase()}</h3>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-3"></div>
    `;
    const list = section.querySelector(".grid");
    if (!list) return;

    shortcutList.forEach((s) => {
      const item = document.createElement("div");
      item.className =
        "flex items-center justify-between p-3 rounded bg-white/5 border border-neutral-800";

      const keysHtml = s.keys
        .map(
          (k) =>
            `<kbd class="px-2 py-1 rounded bg-neutral-800 border border-neutral-700 text-secondary font-mono text-[10px] shadow-sm min-w-[30px] text-center">${k}</kbd>`,
        )
        .join('<span class="mx-1 text-on-surface-variant opacity-40">/</span>');

      item.innerHTML = `
        <span class="text-[11px] font-bold text-white tracking-wider" data-i18n="${
          s.i18nKey
        }">${window.t?.(s.i18nKey, "")}</span>
        <div class="flex items-center">${keysHtml}</div>
      `;
      list.appendChild(item);
    });
    container.appendChild(section);
  });
}

/**
 * Filters the visible shortcuts list based on user search input.
 */
export function filterShortcuts(): void {
  const search = document.getElementById("shortcut-search");
  if (search instanceof HTMLInputElement) {
    renderShortcutsList(search.value.toLowerCase());
  }
}
