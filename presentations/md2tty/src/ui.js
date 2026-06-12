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

/** @fileoverview Handles UI interactions, themes, and overlays. */

import { marked } from 'marked';
import {Themes, THEME_FLASH_DURATION_MS, getHelpMarkdown} from './constants.js';
import { t } from './i18n.js';

/**
 * Updates the footer with current progress and controls.
 * @param {HTMLElement} footer The footer element to update.
 * @param {number} current Current slide index (0-based).
 * @param {number} total Total number of slides.
 * @return {void}
 */
export function updateFooter(footer, current, total) {
  if (!footer) return;

  const slideProgress = t('slide_progress', { Current: current + 1, Total: total });
  footer.innerHTML = `${slideProgress} • ` +
      `<span class="footer-btn" data-action="theme"><b>[t]</b> ${t('theme')}</span> • ` +
      `<span class="footer-btn" data-action="help"><b>[h]</b> ${t('help')}</span> • ` +
      `<span class="footer-btn" data-action="quit"><b>[q]</b> ${t('quit')}</span>`;

  // Append terminal-style blinking cursor.
  const cursor = document.createElement('span');
  cursor.id = 'cursor';
  footer.appendChild(cursor);
}

/**
 * Toggles the shortcuts help overlay.
 * @param {HTMLElement} overlay The overlay element to toggle.
 * @param {boolean=} show Explicitly show or hide the overlay.
 * @param {number=} current Current slide index (for footer).
 * @param {number=} total Total slide count (for footer).
 * @return {boolean} The new visibility state of the overlay.
 */
export function toggleHelp(overlay, show, current = 0, total = 0) {
  if (!overlay) return false;

  const isActive = (show !== undefined) ? show : !overlay.classList.contains('active');
  if (isActive) {
    const content = overlay.querySelector('.shortcuts-content');
    if (content) {
      content.innerHTML = /** @type {string} */ (marked.parse(getHelpMarkdown()));
      content.className = 'shortcuts-content slide-content'; // Reuse slide-content for flex-grow
      
      // Ensure footer is present and pushed to bottom
      let helpFooter = overlay.querySelector('.help-footer');
      if (!helpFooter) {
        helpFooter = document.createElement('footer');
        helpFooter.className = 'help-footer';
        overlay.appendChild(helpFooter);
      }
      updateFooter(/** @type {HTMLElement} */ (helpFooter), current, total);
    }
    overlay.classList.add('active');
  } else {
    overlay.classList.remove('active');
  }
  return isActive;
}

/**
 * Toggles between light and dark themes on the body.
 * @return {void}
 */
export function toggleTheme() {
  document.body.classList.toggle(Themes.LIGHT);
}

/**
 * Briefly flashes the theme for visual feedback during navigation.
 * Toggles the theme and then toggles it back after THEME_FLASH_DURATION_MS.
 * @return {void}
 */
export function flashTheme() {
  toggleTheme();
  setTimeout(() => {
    toggleTheme();
  }, THEME_FLASH_DURATION_MS);
}
