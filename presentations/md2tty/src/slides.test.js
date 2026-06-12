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
import { setTabTitle, renderSlide } from './slides.js';
import { Selectors } from './constants.js';

// Mock dompurify
vi.mock('dompurify', () => ({
  default: {
    sanitize: vi.fn((str) => str),
  },
}));

// Mock marked
vi.mock('marked', () => ({
  marked: {
    parse: vi.fn((str) => `<p>${str}</p>`),
    setOptions: vi.fn(),
  },
}));

describe('slides.js', () => {
  beforeEach(() => {
    document.title = '';
    document.body.innerHTML = `
      <article id="${Selectors.TARGET}"></article>
      <footer id="${Selectors.FOOTER}"></footer>
    `;
  });

  describe('setTabTitle', () => {
    it('sets the document title from the first slide header', () => {
      const contents = ['<!-- Copyright -->\n# Test Title\nContent', '## Slide 2'];
      setTabTitle(contents);
      expect(document.title).toBe('md2tty.js - Test Title');
    });

    it('handles empty contents', () => {
      document.title = 'Initial';
      setTabTitle([]);
      expect(document.title).toBe('Initial');
    });

    it('trims extra whitespace and hashes', () => {
      const contents = ['###   Another Title   '];
      setTabTitle(contents);
      expect(document.title).toBe('md2tty.js - Another Title');
    });

    it('falls back to just md2tty.js if no header is found', () => {
      const contents = ['Just some text\nwithout a header'];
      setTabTitle(contents);
      expect(document.title).toBe('md2tty.js');
    });
  });

  describe('renderSlide', () => {
    it('renders the content to the target element', () => {
      const names = ['00_test.md'];
      const contents = ['Hello World'];
      const target = /** @type {HTMLElement} */ (document.getElementById(Selectors.TARGET));
      const footer = /** @type {HTMLElement} */ (document.getElementById(Selectors.FOOTER));
      
      const index = renderSlide(0, target, footer, names, contents);
      
      expect(target.innerHTML).toBe('<p>Hello World</p>');
      expect(target.className).toContain('slide-00_test');
      expect(index).toBe(0);
    });

    it('constrains index within bounds', () => {
      const names = ['00.md', '01.md'];
      const contents = ['C1', 'C2'];
      const target = /** @type {HTMLElement} */ (document.getElementById(Selectors.TARGET));
      const footer = /** @type {HTMLElement} */ (document.getElementById(Selectors.FOOTER));

      expect(renderSlide(-1, target, footer, names, contents)).toBe(0);
      expect(renderSlide(5, target, footer, names, contents)).toBe(1);
    });

    it('updates the URL hash', () => {
      const names = ['00.md'];
      const contents = ['C1'];
      const target = /** @type {HTMLElement} */ (document.getElementById(Selectors.TARGET));
      const footer = /** @type {HTMLElement} */ (document.getElementById(Selectors.FOOTER));
      const replaceStateSpy = vi.spyOn(history, 'replaceState');
      
      renderSlide(0, target, footer, names, contents);
      
      expect(replaceStateSpy).toHaveBeenCalledWith(null, '', '#1');
    });
  });
});
