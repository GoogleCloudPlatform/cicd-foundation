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

/** @fileoverview Main entry point for the presentation engine. */

import {RESIZE_DEBOUNCE_MS, Selectors, Themes} from './constants.js';
import {initI18n, cycleLanguage, t} from './i18n.js';
import {autoScale} from './scaling.js';
import {initSlides, renderSlide, setTabTitle} from './slides.js';
import {toggleHelp, toggleTheme} from './ui.js';

/**
 * High-fidelity terminal-styled presentation engine.
 */
export class Md2tty {
  /**
   * @param {Object} [options={}] Configuration options.
   * @param {string|HTMLElement} [options.target] Element or selector to render into.
   * @param {string} [options.manifestUrl='slides.json'] URL to slides manifest.
   * @param {string} [options.slidesDir='slides/'] Directory containing slide files.
   */
  constructor(options = {}) {
    /** @type {HTMLElement|null} */
    this.target = typeof options.target === 'string' 
      ? /** @type {HTMLElement|null} */ (document.querySelector(options.target))
      : /** @type {HTMLElement} */ (options.target || null);
    
    this.manifestUrl = options.manifestUrl || 'slides.json';
    this.slidesDir = options.slidesDir || 'slides/';

    /** @type {string[]} */
    this.slideNames = [];
    /** @type {string[]} */
    this.slideContents = [];
    this.currentSlide = 0;
    this.helpVisible = false;
    this.transitionFlash = true;

    // Instance-bound references for elements.
    /** @type {HTMLElement|null} */
    this.footer = null;
    /** @type {HTMLElement|null} */
    this.overlay = null;
    /** @type {HTMLElement|null} */
    this.measureContainer = null;

    // Bind event handlers.
    this.handleKeydown = this.handleKeydown.bind(this);
    this.handleClick = this.handleClick.bind(this);
    this.handleResize = this.handleResize.bind(this);
    /** @type {number | undefined} */
    this.resizeTimer = undefined;
  }

  /**
   * Initializes the presentation and renders the first slide.
   * @return {Promise<void>}
   */
  async init() {
    try {
      await initI18n();

      const urlParams = new URLSearchParams(window.location.search);
      const themeParam = urlParams.get('theme');
      if (themeParam === 'light') {
        document.body.classList.add(Themes.LIGHT);
      } else if (themeParam === 'dark') {
        document.body.classList.remove(Themes.LIGHT);
      }

      const slides = await initSlides(this.manifestUrl, this.slidesDir);
      this.slideNames = slides.names;
      this.slideContents = slides.contents;

      if (this.slideNames.length === 0) {
        if (this.target) this.target.innerHTML = `<p>${t('error_no_slides')}</p>`;
        return;
      }

      this.setupDOM();
      setTabTitle(this.slideContents);
      this.autoScale();
      this.mount();

      const hash = window.location.hash.substring(1);
      const startSlide = (hash && !isNaN(Number(hash))) ? parseInt(hash, 10) - 1 : 0;
      this.goTo(startSlide);
    } catch (err) {
      console.error('Md2tty initialization failed:', err);
    }
  }

  /**
   * Identifies or creates required UI elements within the target.
   * @private
   */
  setupDOM() {
    this.footer = document.getElementById(Selectors.FOOTER);
    this.overlay = document.getElementById(Selectors.OVERLAY);
    this.measureContainer = document.getElementById(Selectors.MEASURE_CONTAINER);
  }

  /**
   * Attaches global event listeners.
   */
  mount() {
    window.addEventListener('keydown', this.handleKeydown);
    window.addEventListener('click', this.handleClick);
    window.addEventListener('resize', this.handleResize);
  }

  /**
   * Detaches global event listeners.
   */
  unmount() {
    window.removeEventListener('keydown', this.handleKeydown);
    window.removeEventListener('click', this.handleClick);
    window.removeEventListener('resize', this.handleResize);
  }

  /**
   * Triggers the auto-scaling logic for the current viewport.
   */
  autoScale() {
    autoScale(this.slideContents, /** @type {HTMLElement} */ (this.target), /** @type {HTMLElement} */ (this.measureContainer));
  }

  /**
   * Navigates to a specific slide by index.
   * @param {number} index
   */
  goTo(index) {
    this.currentSlide = renderSlide(
      index, 
      /** @type {HTMLElement} */ (this.target), 
      /** @type {HTMLElement} */ (this.footer), 
      this.slideNames, 
      this.slideContents,
      this.transitionFlash
    );
  }

  /**
   * Navigates to the next slide.
   */
  next() {
    this.goTo(this.currentSlide + 1);
  }

  /**
   * Navigates to the previous slide.
   */
  prev() {
    this.goTo(this.currentSlide - 1);
  }

  /**
   * Toggles the help overlay.
   * @param {boolean} [show] Force a specific state.
   */
  toggleHelp(show) {
    this.helpVisible = toggleHelp(
      /** @type {HTMLElement} */ (this.overlay), 
      show, 
      this.currentSlide, 
      this.slideContents.length
    );
  }

  /**
   * Internal Keydown handler.
   * @param {KeyboardEvent} e
   * @private
   */
  handleKeydown(e) {
    if (this.slideContents.length === 0) return;

    if (e.key >= '1' && e.key <= '9') {
      const num = parseInt(e.key, 10) - 1;
      if (num < this.slideContents.length) {
        this.goTo(num);
        if (this.helpVisible) this.toggleHelp(false);
      }
      return;
    }

    switch (e.key) {
      case 't': case 'T':
        toggleTheme();
        return;
      case 'l': case 'L':
        cycleLanguage();
        if (this.helpVisible) {
          this.toggleHelp(true);
        } else {
          this.goTo(this.currentSlide);
        }
        return;
      case 'f': case 'F':
        this.transitionFlash = !this.transitionFlash;
        return;
      case 'q': case 'Q':
        window.close();
        if (this.target) {
          this.target.innerHTML = '<h1>Presentation Ended</h1>\n<p>You can safely close this tab.</p>';
          this.target.className = 'slide-content';
        }
        return;
    }

    if (this.helpVisible) {
      this.toggleHelp(false);
      e.preventDefault();
      return;
    }

    switch (e.key) {
      case 'h': case 'H': case '?':
        this.toggleHelp(true);
        break;
      case 'PageDown': case 'ArrowRight': case 'ArrowDown':
      case 'j': case 'n': case 's': case ' ': case 'Enter':
        this.next();
        break;
      case 'PageUp': case 'ArrowLeft': case 'ArrowUp':
      case 'k': case 'p': case 'w': case 'Backspace':
        this.prev();
        break;
      case 'Home':
        this.goTo(0);
        break;
      case 'End':
        this.goTo(this.slideContents.length - 1);
        break;
    }
  }

  /**
   * Internal Click handler.
   * @param {MouseEvent} e
   * @private
   */
  handleClick(e) {
    const target = /** @type {HTMLElement} */ (e.target);
    const footerBtn = target.closest('.footer-btn');
    if (footerBtn) {
      const action = footerBtn.getAttribute('data-action');
      if (action === 'theme') {
        toggleTheme();
      } else if (action === 'flash') {
        this.transitionFlash = !this.transitionFlash;
      } else if (action === 'help') {
        this.toggleHelp(true);
      } else if (action === 'quit') {
        window.close();
        if (this.target) {
          this.target.innerHTML = '<h1>Presentation Ended</h1>\n<p>You can safely close this tab.</p>';
          this.target.className = 'slide-content';
        }
      }
      return; // Stop processing after handling button
    }

    if (this.helpVisible) {
      this.toggleHelp(false);
    }
  }

  /**
   * Internal Resize handler (debounced).
   * @private
   */
  handleResize() {
    clearTimeout(this.resizeTimer);
    this.resizeTimer = setTimeout(() => this.autoScale(), RESIZE_DEBOUNCE_MS);
  }
}
