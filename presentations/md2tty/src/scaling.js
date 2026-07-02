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

/** @fileoverview Handles dynamic font scaling to fit slides to the viewport. */

import { marked } from 'marked';
import {INITIAL_FONT_SIZE, SCALE_MARGIN, Selectors} from './constants.js';

/**
 * Calculates and applies the optimal font size to fill the viewport.
 * @param {!Array<string>} slideContents List of Markdown contents to measure.
 * @param {HTMLElement} target The target element to render into.
 * @param {HTMLElement} measureContainer The container to use for measurements.
 * @param {number} [viewportW=window.innerWidth] Viewport width to scale against.
 * @param {number} [viewportH=window.innerHeight] Viewport height to scale against.
 * @return {void}
 */
export function autoScale(
  slideContents, 
  target, 
  measureContainer, 
  viewportW = window.innerWidth, 
  viewportH = window.innerHeight
) {
  if (!slideContents || slideContents.length === 0 || !measureContainer) return;

  // Reset to a known base to measure.
  document.documentElement.style.setProperty('--base-font-size', `${INITIAL_FONT_SIZE}px`);

  let maxW = 0;
  let maxH = 0;

  measureContainer.style.fontSize = `${INITIAL_FONT_SIZE}px`;
  measureContainer.style.width = 'auto';
  measureContainer.style.maxWidth = '80ch'; // Enforce terminal-like max width
  measureContainer.style.display = 'inline-block';

  slideContents.forEach((md) => {
    measureContainer.innerHTML = /** @type {string} */ (marked.parse(md));
    // Use scrollWidth/Height to capture content size even if it overflows maxWidth (e.g. wide code blocks)
    maxW = Math.max(maxW, measureContainer.scrollWidth + 60);
    // 100px buffer for header/footer/padding.
    maxH = Math.max(maxH, measureContainer.scrollHeight + 100);
  });

  const scaleW = viewportW / maxW;
  const scaleH = viewportH / maxH;

  // Use the smaller ratio, with a small safety margin.
  const scale = Math.min(scaleW, scaleH) * SCALE_MARGIN;

  const finalFontSize = Math.max(10, Math.floor(INITIAL_FONT_SIZE * scale));
  document.documentElement.style.setProperty('--base-font-size', `${finalFontSize}px`);
}
