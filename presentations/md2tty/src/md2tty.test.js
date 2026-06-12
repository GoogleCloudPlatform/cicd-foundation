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

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { Md2tty } from './md2tty.js';
import { Selectors, Themes } from './constants.js';
import * as ui from './ui.js';
import * as slides from './slides.js';
import * as i18n from './i18n.js';

// Mock dependencies
vi.mock('./ui.js', async (importOriginal) => {
  const actual = /** @type {any} */ (await importOriginal());
  return {
    ...actual,
    toggleHelp: vi.fn((overlay, show) => show !== undefined ? show : true),
    toggleTheme: vi.fn(),
  };
});

vi.mock('./slides.js', () => ({
  initSlides: vi.fn().mockResolvedValue({ names: ['slide1.md', 'slide2.md'], contents: ['content 1', 'content 2'] }),
  renderSlide: vi.fn((index) => index),
  setTabTitle: vi.fn(),
}));

vi.mock('./i18n.js', () => ({
  initI18n: vi.fn().mockResolvedValue(),
  cycleLanguage: vi.fn(),
  t: vi.fn((key) => key)
}));

describe('Md2tty', () => {
  /** @type {Md2tty} */
  let app;

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="${Selectors.TARGET}"></div>
      <div id="${Selectors.FOOTER}"></div>
      <div id="${Selectors.OVERLAY}"></div>
      <div id="${Selectors.MEASURE_CONTAINER}"></div>
    `;
    app = new Md2tty({ target: `#${Selectors.TARGET}` });
    app.slideContents = ['Slide 1', 'Slide 2', 'Slide 3'];
    app['setupDOM']();
  });

  afterEach(() => {
    vi.clearAllMocks();
    document.body.innerHTML = '';
    window.history.pushState({}, '', '/');
  });

  describe('init', () => {
    it('initializes successfully with slides', async () => {
      const autoScaleSpy = vi.spyOn(app, 'autoScale').mockImplementation(() => {});
      const mountSpy = vi.spyOn(app, 'mount').mockImplementation(() => {});
      const goToSpy = vi.spyOn(app, 'goTo').mockImplementation(() => {});

      await app.init();

      expect(i18n.initI18n).toHaveBeenCalled();
      expect(slides.initSlides).toHaveBeenCalled();
      expect(app.slideNames).toEqual(['slide1.md', 'slide2.md']);
      expect(autoScaleSpy).toHaveBeenCalled();
      expect(mountSpy).toHaveBeenCalled();
      expect(goToSpy).toHaveBeenCalledWith(0);
    });

    it('sets theme from URL parameter', async () => {
      window.history.pushState({}, '', '/?theme=light');
      const mockInitSlides = vi.spyOn(slides, 'initSlides').mockResolvedValue({ names: [], contents: [] });
      await app.init();
      expect(document.body.classList.contains(Themes.LIGHT)).toBe(true);
      mockInitSlides.mockRestore();
    });

    it('handles empty slides', async () => {
      const mockInitSlides = vi.spyOn(slides, 'initSlides').mockResolvedValue({ names: [], contents: [] });
      const mountSpy = vi.spyOn(app, 'mount');
      
      await app.init();
      
      expect(app.target.innerHTML).toContain('error_no_slides');
      expect(mountSpy).not.toHaveBeenCalled();
      mockInitSlides.mockRestore();
    });

    it('catches initialization errors', async () => {
      const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
      const mockInitSlides = vi.spyOn(slides, 'initSlides').mockRejectedValue(new Error('init error'));
      
      await app.init();
      
      expect(consoleErrorSpy).toHaveBeenCalled();
      mockInitSlides.mockRestore();
    });
  });

  describe('mount/unmount and lifecycle', () => {
    it('adds and removes event listeners', () => {
      const addSpy = vi.spyOn(window, 'addEventListener');
      const removeSpy = vi.spyOn(window, 'removeEventListener');

      app.mount();
      expect(addSpy).toHaveBeenCalledWith('keydown', app.handleKeydown);
      expect(addSpy).toHaveBeenCalledWith('click', app.handleClick);
      expect(addSpy).toHaveBeenCalledWith('resize', app.handleResize);

      app.unmount();
      expect(removeSpy).toHaveBeenCalledWith('keydown', app.handleKeydown);
      expect(removeSpy).toHaveBeenCalledWith('click', app.handleClick);
      expect(removeSpy).toHaveBeenCalledWith('resize', app.handleResize);
    });

    it('debounces resize events', () => {
      vi.useFakeTimers();
      const autoScaleSpy = vi.spyOn(app, 'autoScale').mockImplementation(() => {});
      
      app.handleResize();
      app.handleResize();
      app.handleResize();
      
      vi.runAllTimers();
      
      expect(autoScaleSpy).toHaveBeenCalledTimes(1);
      vi.useRealTimers();
    });
  });

  describe('navigation', () => {
    it('goTo calls renderSlide with current index', () => {
      app.goTo(2);
      expect(slides.renderSlide).toHaveBeenCalledWith(2, app.target, app.footer, app.slideNames, app.slideContents, app.transitionFlash);
      expect(app.currentSlide).toBe(2);
    });

    it('next and prev update currentSlide', () => {
      const goToSpy = vi.spyOn(app, 'goTo').mockImplementation((idx) => { app.currentSlide = idx; });
      app.currentSlide = 1;
      
      app.next();
      expect(goToSpy).toHaveBeenCalledWith(2);
      
      app.prev();
      expect(goToSpy).toHaveBeenCalledWith(1);
    });
  });

  describe('handleClick', () => {
    it('closes help if visible', () => {
      app.helpVisible = true;
      const toggleHelpSpy = vi.spyOn(app, 'toggleHelp');
      app['handleClick']({ target: document.body });
      expect(toggleHelpSpy).toHaveBeenCalledWith(false);
    });

    it('handles footer button clicks', () => {
      app.helpVisible = false;
      const toggleThemeSpy = vi.spyOn(ui, 'toggleTheme');
      const toggleHelpSpy = vi.spyOn(app, 'toggleHelp');
      const windowCloseSpy = vi.spyOn(window, 'close').mockImplementation(() => {});

      const createBtn = (action) => {
        const btn = document.createElement('span');
        btn.className = 'footer-btn';
        btn.setAttribute('data-action', action);
        return btn;
      };

      app['handleClick']({ target: createBtn('theme') });
      expect(toggleThemeSpy).toHaveBeenCalled();

      expect(app.transitionFlash).toBe(true);
      app['handleClick']({ target: createBtn('flash') });
      expect(app.transitionFlash).toBe(false);

      app['handleClick']({ target: createBtn('help') });
      expect(toggleHelpSpy).toHaveBeenCalledWith(true);

      app.helpVisible = false; // Reset state for next click
      app['handleClick']({ target: createBtn('quit') });
      expect(windowCloseSpy).toHaveBeenCalled();
    });
  });

  describe('Keyboard Handling', () => {
    describe('when help is visible', () => {
    beforeEach(() => {
      app.helpVisible = true;
    });

    it('toggles theme and keeps help open on "t"', () => {
      const event = new KeyboardEvent('keydown', { key: 't' });
      const toggleHelpSpy = vi.spyOn(app, 'toggleHelp');

      app['handleKeydown'](event);

      expect(ui.toggleTheme).toHaveBeenCalled();
      expect(toggleHelpSpy).not.toHaveBeenCalled();
      expect(app.helpVisible).toBe(true);
    });

    it('toggles transitionFlash and keeps help open on "f"', () => {
      const event = new KeyboardEvent('keydown', { key: 'f' });
      const toggleHelpSpy = vi.spyOn(app, 'toggleHelp');

      expect(app.transitionFlash).toBe(true);
      app['handleKeydown'](event);
      expect(app.transitionFlash).toBe(false);

      expect(toggleHelpSpy).not.toHaveBeenCalled();
      expect(app.helpVisible).toBe(true);
    });

    it('jumps to slide and closes help on "1-9"', () => {
      const event = new KeyboardEvent('keydown', { key: '2' });
      const goToSpy = vi.spyOn(app, 'goTo');
      const toggleHelpSpy = vi.spyOn(app, 'toggleHelp');

      app['handleKeydown'](event);

      expect(goToSpy).toHaveBeenCalledWith(1);
      expect(toggleHelpSpy).toHaveBeenCalledWith(false);
    });

    it('closes help on other keys', () => {
      const event = new KeyboardEvent('keydown', { key: 'Enter' });
      const toggleHelpSpy = vi.spyOn(app, 'toggleHelp');

      app['handleKeydown'](event);

      expect(toggleHelpSpy).toHaveBeenCalledWith(false);
    });

    it('attempts to close window on "q"', () => {
      const closeSpy = vi.spyOn(window, 'close').mockImplementation(() => {});
      const event = new KeyboardEvent('keydown', { key: 'q' });

      app['handleKeydown'](event);

      expect(closeSpy).toHaveBeenCalled();
    });
  });

  describe('when showing a presentation slide', () => {
    beforeEach(() => {
      app.helpVisible = false;
    });

    it('attempts to close window on "q"', () => {
      const closeSpy = vi.spyOn(window, 'close').mockImplementation(() => {});
      const event = new KeyboardEvent('keydown', { key: 'q' });

      app['handleKeydown'](event);

      expect(closeSpy).toHaveBeenCalled();
    });
  });
});
});
