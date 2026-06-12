/*!
 * @license
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

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { updateFooter, toggleHelp, toggleTheme, flashTheme } from './ui.js';
import { Selectors, Themes, THEME_FLASH_DURATION_MS } from './constants.js';

describe('ui.js', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div id="${Selectors.FOOTER}"></div>
      <div id="${Selectors.OVERLAY}"></div>
    `;
    document.body.className = '';
  });

  describe('updateFooter', () => {
    it('renders the correct slide progress', () => {
      const footer = /** @type {HTMLElement} */ (document.getElementById(Selectors.FOOTER));
      updateFooter(footer, 0, 5);
      expect(footer.textContent).toContain('slide_progress');
      expect(footer.textContent).toContain('help');
    });

    it('appends a blinking cursor', () => {
      const footer = /** @type {HTMLElement} */ (document.getElementById(Selectors.FOOTER));
      updateFooter(footer, 2, 10);
      const cursor = document.getElementById('cursor');
      expect(cursor).not.toBeNull();
    });
  });

  describe('toggleHelp', () => {
    it('toggles the active class on the overlay', () => {
      const overlay = /** @type {HTMLElement} */ (document.getElementById(Selectors.OVERLAY));
      
      toggleHelp(overlay, true);
      expect(overlay.classList.contains('active')).toBe(true);
      
      toggleHelp(overlay, false);
      expect(overlay.classList.contains('active')).toBe(false);
    });

    it('toggles automatically if no argument is provided', () => {
      const overlay = /** @type {HTMLElement} */ (document.getElementById(Selectors.OVERLAY));
      
      toggleHelp(overlay);
      expect(overlay.classList.contains('active')).toBe(true);
      
      toggleHelp(overlay);
      expect(overlay.classList.contains('active')).toBe(false);
    });
  });

  describe('toggleTheme', () => {
    it('toggles the light-theme class on the body', () => {
      toggleTheme();
      expect(document.body.classList.contains(Themes.LIGHT)).toBe(true);
      
      toggleTheme();
      expect(document.body.classList.contains(Themes.LIGHT)).toBe(false);
    });
  });

  describe('flashTheme', () => {
    it('toggles the theme twice with a delay', async () => {
      vi.useFakeTimers();
      
      flashTheme();
      expect(document.body.classList.contains(Themes.LIGHT)).toBe(true);
      
      vi.advanceTimersByTime(THEME_FLASH_DURATION_MS);
      expect(document.body.classList.contains(Themes.LIGHT)).toBe(false);
      
      vi.useRealTimers();
    });
  });
});
