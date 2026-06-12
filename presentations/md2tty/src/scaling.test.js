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
import { autoScale } from './scaling.js';
import { INITIAL_FONT_SIZE } from './constants.js';

vi.mock('marked', () => ({
  marked: {
    parse: vi.fn((str) => `<p>${str}</p>`)
  }
}));

describe('scaling', () => {
  let target;
  let measureContainer;

  beforeEach(() => {
    target = document.createElement('div');
    measureContainer = document.createElement('div');
    document.body.appendChild(target);
    document.body.appendChild(measureContainer);

    // Mock window innerWidth and innerHeight
    vi.stubGlobal('innerWidth', 1000);
    vi.stubGlobal('innerHeight', 800);

    // Mock offsetWidth and offsetHeight for measureContainer
    Object.defineProperty(measureContainer, 'offsetWidth', { configurable: true, value: 400 });
    Object.defineProperty(measureContainer, 'offsetHeight', { configurable: true, value: 300 });
  });

  afterEach(() => {
    document.body.innerHTML = '';
    vi.unstubAllGlobals();
  });

  it('bails out early if missing arguments', () => {
    const setPropertySpy = vi.spyOn(document.documentElement.style, 'setProperty');
    autoScale([], target, measureContainer);
    expect(setPropertySpy).not.toHaveBeenCalled();

    autoScale(['slide'], target, null);
    expect(setPropertySpy).not.toHaveBeenCalled();
  });

  it('calculates scale and sets --base-font-size on document.documentElement', () => {
    const setPropertySpy = vi.spyOn(document.documentElement.style, 'setProperty');
    
    autoScale(['# slide 1', '# slide 2'], target, measureContainer);
    
    // maxW = 400 + 60 = 460
    // maxH = 300 + 100 = 400
    // viewportW = 1000, viewportH = 800
    // scaleW = 1000 / 460 = 2.17
    // scaleH = 800 / 400 = 2.0
    // scale = Math.min(2.17, 2.0) * 0.95 = 2.0 * 0.95 = 1.9
    // finalFontSize = Math.max(10, Math.floor(INITIAL_FONT_SIZE * 1.9)) = Math.max(10, Math.floor(20 * 1.9)) = Math.max(10, 38) = 38
    
    expect(setPropertySpy).toHaveBeenCalledWith('--base-font-size', '20px');
    expect(setPropertySpy).toHaveBeenCalledWith('--base-font-size', '38px');
  });
});
