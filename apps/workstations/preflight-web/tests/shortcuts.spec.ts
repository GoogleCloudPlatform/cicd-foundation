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
import { setupMockDOM } from "./helpers";
import {
  initGlobalShortcuts,
  renderShortcutsList,
  filterShortcuts,
  shortcuts,
} from "../shortcuts_module";

describe("Shortcuts Module", () => {
  beforeEach(() => {
    setupMockDOM();
    state.currentModal = null;
    state.isHealthy = false;

    window.openModal = vi.fn();
    window.closeAllModals = vi.fn();
    window.toggleDebug = vi.fn();
    window.reportBug = vi.fn();
    window.toggleRetry = vi.fn();
    window.manualConnect = vi.fn();

    initGlobalShortcuts();
  });

  const fireKey = (key: string): void => {
    window.dispatchEvent(new KeyboardEvent("keydown", { key }));
  };

  test("Shortcuts are ignored if a modal is open (except Escape)", () => {
    state.currentModal = "settings-modal";
    fireKey("d"); // Toggle debug
    expect(window.toggleDebug).not.toHaveBeenCalled();

    fireKey("Escape");
    expect(window.closeAllModals).toHaveBeenCalled();
  });

  test("'?' and 'h' open help modal (merged entry) when no modal open", () => {
    fireKey("?");
    expect(window.openModal).toHaveBeenCalledWith("help-modal");
    vi.clearAllMocks();
    fireKey("h");
    expect(window.openModal).toHaveBeenCalledWith("help-modal");
  });

  test("'d' toggles debug info when no modal open", () => {
    fireKey("d");
    expect(window.toggleDebug).toHaveBeenCalled();
  });

  test("'Space' toggles retry when no modal open", () => {
    fireKey(" ");
    expect(window.toggleRetry).toHaveBeenCalled();
  });

  test("Shortcuts are ignored in inputs/textareas, but Escape blurs", () => {
    const input = document.createElement("input");
    document.body.appendChild(input);
    input.focus();

    fireKey("d");
    expect(window.toggleDebug).not.toHaveBeenCalled();

    const blurSpy = vi.spyOn(input, "blur");
    fireKey("Escape");
    expect(blurSpy).toHaveBeenCalled();
  });
  test("initGlobalShortcuts coverage", () => {
    initGlobalShortcuts();
    document.body.innerHTML =
      '<input id="inp" /><textarea id="txt"></textarea>';
    const inp = document.getElementById("inp") as HTMLInputElement;
    inp.focus();
    inp.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    inp.dispatchEvent(
      new KeyboardEvent("keydown", { key: "A", bubbles: true }),
    );

    const txt = document.getElementById("txt") as HTMLTextAreaElement;
    txt.focus();
    txt.dispatchEvent(new KeyboardEvent("keydown", { key: "Space" }));

    inp.blur();
    txt.blur();
    state.currentModal = "some";
    document.body.dispatchEvent(new KeyboardEvent("keydown", { key: "Space" }));
  });
  test("initGlobalShortcuts with modal", () => {
    state.currentModal = "some";
    document.body.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));
    document.body.dispatchEvent(
      new KeyboardEvent("keydown", { key: "Escape" }),
    );
    state.currentModal = null;
    document.body.dispatchEvent(new KeyboardEvent("keydown", { key: " " }));
  });
  test("execute shortcut actions", () => {
    window.openModal = vi.fn();
    window.manualConnect = vi.fn();
    window.toggleRetry = vi.fn();
    window.closeAllModals = vi.fn();
    window.toggleDebug = vi.fn();
    window.reportBug = vi.fn();
    shortcuts.forEach((s) => s.action());
    expect(window.openModal).toHaveBeenCalled();
  });
  test("renderShortcutsList with filter & missing grid", () => {
    document.body.innerHTML = '<div id="shortcuts-list-container"></div>';
    const orig = document.createElement;
    document.createElement = vi.fn().mockImplementation((tag) => {
      const el = orig.call(document, tag);
      if (tag === "div") {
        el.querySelector = () => null;
      }
      return el;
    });
    renderShortcutsList("help");
    document.createElement = orig;
  });
  test("filterShortcuts", () => {
    document.body.innerHTML =
      '<input id="shortcut-search" value="s"/><div id="shortcuts-list-container"></div>';
    filterShortcuts();

    document.body.innerHTML =
      '<input id="shortcut-search" value="x"/><div id="shortcuts-list-container"></div>';
    filterShortcuts();
  });
});
