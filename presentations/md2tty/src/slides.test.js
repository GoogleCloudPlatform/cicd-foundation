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
import { setTabTitle, renderAllSlides, activateSlide } from './slides.js';
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

  describe('renderAllSlides', () => {
    it('renders all slides and their footers into the container', () => {
      const names = ['00_test.md', '01_test.md'];
      const contents = ['Hello', 'World'];
      const container = document.createElement('div');

      renderAllSlides(container, names, contents);

      const slides = container.querySelectorAll('.slide-content');
      expect(slides.length).toBe(2);
      expect(slides[0].querySelector('.slide-body').innerHTML).toBe('<p>Hello</p>');
      expect(slides[0].className).toContain('slide-00_test');
      expect(slides[0].querySelector('footer')).toBeTruthy();

      expect(slides[1].querySelector('.slide-body').innerHTML).toBe('<p>World</p>');
      expect(slides[1].className).toContain('slide-01_test');
    });
  });

  describe('activateSlide', () => {
    let container;
    beforeEach(() => {
      container = document.createElement('div');
      const names = ['00.md', '01.md'];
      const contents = ['C1', 'C2'];
      renderAllSlides(container, names, contents);
    });

    it('sets active class on the target slide and removes from others', () => {
      const index = activateSlide(1, container);

      const slides = container.querySelectorAll('.slide-content');
      expect(slides[0].classList.contains('active')).toBe(false);
      expect(slides[1].classList.contains('active')).toBe(true);
      expect(index).toBe(1);
    });

    it('constrains index within bounds', () => {
      expect(activateSlide(-1, container)).toBe(0);
      expect(activateSlide(5, container)).toBe(1);
    });

    it('updates the URL hash', () => {
      const replaceStateSpy = vi.spyOn(history, 'replaceState');
      activateSlide(0, container);
      expect(replaceStateSpy).toHaveBeenCalledWith(null, '', '#1');
    });
  });
});
