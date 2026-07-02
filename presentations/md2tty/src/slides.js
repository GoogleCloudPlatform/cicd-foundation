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
 * Renders all slides into the container at startup.
 * @param {HTMLElement} container The container to render slides into.
 * @param {!Array<string>} slideNames
 * @param {!Array<string>} slideContents
 */
export function renderAllSlides(container, slideNames, slideContents) {
  if (!container) return;
  container.innerHTML = '';

  slideContents.forEach((content, index) => {
    const article = document.createElement('article');
    const slideId = slideNames[index].replace('.md', '');
    article.className = `slide-content slide-${slideId}`;
    article.setAttribute('data-index', index);

    // Slide body
    const bodyDiv = document.createElement('div');
    bodyDiv.className = 'slide-body';
    bodyDiv.innerHTML = /** @type {string} */ (marked.parse(content));
    article.appendChild(bodyDiv);

    // Slide footer (per-slide for printing)
    const footer = document.createElement('footer');
    footer.className = 'slide-footer';
    article.appendChild(footer);
    updateFooter(footer, index, slideContents.length);

    container.appendChild(article);
  });
}

/**
 * Activates a specific slide by index.
 * @param {number} index Slide index to render.
 * @param {HTMLElement} container The container holding all slides.
 * @param {boolean=} flash Whether to apply the theme flash effect.
 * @return {number} The index of the slide that was activated.
 */
export function activateSlide(index, container, flash = false) {
  if (index < 0) index = 0;
  const slides = container.querySelectorAll('.slide-content');
  if (slides.length === 0) return index;
  if (index >= slides.length) index = slides.length - 1;

  if (flash) flashTheme();

  slides.forEach((slide, idx) => {
    if (idx === index) {
      slide.classList.add('active');
    } else {
      slide.classList.remove('active');
    }
  });

  // Update URL hash.
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

/**
 * Updates all slide footers (used when language changes).
 * @param {HTMLElement} container The container holding all slides.
 * @param {number} totalSlides Total slide count.
 */
export function updateAllFooters(container, totalSlides) {
  if (!container) return;
  const footers = container.querySelectorAll('.slide-footer');
  footers.forEach((footer, index) => {
    updateFooter(footer, index, totalSlides);
  });
}
