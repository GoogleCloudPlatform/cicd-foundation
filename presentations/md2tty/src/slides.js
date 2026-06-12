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

/** @fileoverview Handles slide loading, rendering, and title extraction. */

import DOMPurify from 'dompurify';
import { marked } from 'marked';
import {Selectors} from './constants.js';
import {updateFooter, flashTheme} from './ui.js';

// Configure marked options locally.
marked.setOptions({
  breaks: true,
  gfm: true
});

/**
 * Extracts and sets the document title from the first slide.
 * @param {!Array<string>} slideContents All slide Markdown contents.
 * @return {void}
 */
export function setTabTitle(slideContents) {
  if (slideContents.length === 0) return;
  const firstSlide = slideContents[0];
  
  // Find the first line that starts with a markdown header (#)
  const match = firstSlide.match(/^#+\s+(.+)$/m);
  const title = match && match[1] ? match[1].trim() : '';
  
  if (title) {
    document.title = `md2tty.js - ${title}`;
  } else {
    document.title = 'md2tty.js';
  }
}

/**
 * Renders a specific slide to the DOM.
 * @param {number} index Slide index to render.
 * @param {HTMLElement} target The target element to render into.
 * @param {HTMLElement} footer The footer element to update.
 * @param {!Array<string>} slideNames Filenames for class generation.
 * @param {!Array<string>} slideContents Content to render.
 * @param {boolean=} flash Whether to apply the theme flash effect.
 * @return {number} The index of the slide that was rendered.
 */
export function renderSlide(index, target, footer, slideNames, slideContents, flash = false) {
  if (index < 0) index = 0;
  if (index >= slideContents.length) index = slideContents.length - 1;

  if (flash) flashTheme();

  if (!target) return index;

  target.innerHTML = /** @type {string} */ (marked.parse(slideContents[index]));

  const slideId = slideNames[index].replace('.md', '');
  target.className = `slide-content slide-${slideId}`;

  updateFooter(footer, index, slideContents.length);

  // Update URL hash without polluting history.
  history.replaceState(null, '', `#${index + 1}`);

  return index;
}

/**
 * Fetches all slides based on a manifest URL.
 * @param {string} manifestUrl The URL to the slides.json manifest.
 * @param {string} slidesDir The directory where slides are located.
 * @return {!Promise<{names: !Array<string>, contents: !Array<string>}>}
 */
export async function initSlides(manifestUrl = 'slides.json', slidesDir = 'slides/') {
  const response = await fetch(manifestUrl);
  if (!response.ok) throw new Error(`Failed to load manifest: ${manifestUrl}`);
  
  /** @type {!Array<string>} */
  const names = await response.json();
  
  const fetchPromises = names.map((name) =>
      fetch(`${slidesDir}${name}`).then((r) => r.text()));
  const contents = await Promise.all(fetchPromises);

  return {names, contents};
}
