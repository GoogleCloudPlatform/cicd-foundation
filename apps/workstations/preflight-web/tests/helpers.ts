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

/**
 * Creates a mock Response object for fetch tests.
 * @param data The data to return in the response body.
 * @param headers Optional headers to include in the response.
 * @returns A mock Response object.
 */
export function createMockResponse(
  data: unknown,
  headers: Record<string, string> = {},
): Response {
  const textData = typeof data === "string" ? data : JSON.stringify(data);
  return {
    ok: true,
    status: 200,
    statusText: "OK",
    json: () => Promise.resolve(data),
    text: () => Promise.resolve(textData),
    blob: () =>
      Promise.resolve({
        arrayBuffer: () => Promise.resolve(new ArrayBuffer(0)),
        text: () => Promise.resolve(textData),
      } as unknown as Blob),
    headers: new Headers(headers),
  } as Response;
}

export const MOCK_TRANSLATIONS: Record<string, string> = {
  status_starting: "STARTING",
  status_ready: "READY",
  status_message: "Redirecting...",
  status_message_manual: "Manual wait...",
  status_message_ready: "Ready!",
  status_message_timeout: "Timeout warning",
  status_message_permanent_failure: "Perm failure",
  desc_shortcut_s: "Settings",
  desc_shortcut_space: "Pause / Resume Auto-Retry",
  label_debug_latency: "Latency",
  label_debug_unit_ms: "ms",
  label_auto_retry: "Enable Auto Redirect",
  label_protocol_rdp: "Remote Desktop Protocol (RDP)",
  label_protocol_ssh: "Secure Shell (SSH)",
  label_protocol_vnc: "Virtual Network Computing (VNC)",
};

/**
 * Sets up a mock DOM environment for Preflight tests.
 * Initializes common UI elements and mocks global window functions.
 */
export function setupMockDOM(): void {
  document.body.innerHTML = `
    <div class="starfield-container"></div>
    <div id="ui-wrapper" class="opacity-0">
      <div id="debug-container" class="hidden">
        <span data-i18n="label_debug_info">DEBUG</span>
        <div id="debug-info-content"></div>
      </div>
      <h1 id="main-status" data-i18n="status_starting">STARTING</h1>
      <p id="status-message" data-i18n="status_message"></p>
      <span id="status-icon"></span>
      <button id="btn-open-settings-timer"><div id="live-timer">00:00</div></button>
      <button id="desktop-icon-trigger"></button>
      <div id="display-hostname"></div>
      <div id="display-uplink"></div>
      <button id="btn-open-settings-uplink">Uplink</button>
      <svg><circle id="progress-ring-path"></circle></svg>
      <button id="btn-open-settings"></button>
      <button id="btn-open-language"></button>
      <button id="btn-open-help"></button>

      <div id="settings-modal" class="hidden">
         <button id="btn-close-settings"></button>
         <button id="btn-reset-config"></button>
         <button id="btn-update-config"></button>
         <button id="btn-copy-settings-url"><span id="copy-tooltip">Copy URL</span></button>
         <button id="btn-report-bug"></button>

         <details id="basic-settings-details" open>
           <div id="connection-type-list"></div>
           <button id="btn-settings-open-language"></button>
           <span id="display-active-lang"></span>
         </details>

         <details id="advanced-settings-details">
           <input type="checkbox" id="retry-enable" checked />
           <div id="retry-interval-group">
              <input id="retry-interval" type="range" min="0" max="100" value="50" />
              <span id="retry-value"></span>
           </div>
           <input type="checkbox" id="debug-enable" />
           <input id="timeout-limit" type="range" min="0" max="100" value="50" />
           <span id="timeout-value"></span>
           <input id="simulate-sec" type="range" min="0" max="120" value="0" />
           <span id="simulate-value"></span>
         </details>
      </div>

      <div id="language-modal" class="hidden">
        <button id="btn-close-language"></button>
        <input id="language-search" />
        <div id="language-list"></div>
      </div>
      <div id="help-modal" class="hidden">
        <button id="btn-close-help"></button>
        <button id="btn-open-shortcuts-from-help"></button>
        <button id="btn-open-licenses-from-help"></button>
      </div>
      <div id="shortcuts-modal" class="hidden">
        <button id="btn-close-shortcuts"></button>
        <input id="shortcut-search" />
        <div id="shortcuts-list-container"></div>
      </div>
      <div id="license-modal" class="hidden">
        <button id="btn-close-license"></button>
        <div id="license-list-container"></div>
        <div id="component-details" class="hidden">
          <button id="back-to-details-btn"></button>
          <div id="license-viewer" class="hidden">
             <div id="license-text-content"></div>
          </div>
        </div>
      </div>
    </div>
  `;

  // Mock global functions
  window.t = (key: string, def: string): string =>
    MOCK_TRANSLATIONS[key] || def;
  window.applyTranslations = vi.fn();
  window.updateUIFromConfig = vi.fn();
  window.syncRetryIntervalState = vi.fn();

  // In jsdom v30+, redefining window.location throws an error.
  // Instead, test files should mock `windowUtils` from '../window_utils.ts'.

  // Mock history.replaceState to avoid SecurityError in JSDOM
  Object.defineProperty(window.history, "replaceState", {
    value: vi.fn(),
    configurable: true,
  });

  const writeTextMock = vi.fn().mockImplementation(() => Promise.resolve());
  Object.defineProperty(navigator, "clipboard", {
    value: { writeText: writeTextMock },
    configurable: true,
  });

  window.open = vi.fn() as unknown as (
    url?: string | URL,
    target?: string,
    features?: string,
  ) => Window | null;
}
