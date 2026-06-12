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
import { initI18n, cycleLanguage, t } from './i18n.js';

describe('i18n', () => {
  beforeEach(() => {
    // Reset DOM and translations
    vi.stubGlobal('fetch', vi.fn().mockImplementation((url) => {
      const lang = url.replace('locales/', '').replace('.json', '');
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve([{ id: 'test_key', translation: `translated_in_${lang}` }])
      });
    }));
    
    // Clear URL parameters
    window.history.pushState({}, '', '/');
  });

  describe('initI18n', () => {
    it('initializes with browser language', async () => {
      vi.stubGlobal('navigator', { language: 'fr-FR' });
      await initI18n();
      expect(t('test_key')).toBe('translated_in_fr');
    });

    it('initializes with url parameter if present', async () => {
      window.history.pushState({}, '', '/?lang=es');
      vi.stubGlobal('navigator', { language: 'en-US' });
      await initI18n();
      expect(t('test_key')).toBe('translated_in_es');
    });

    it('falls back to english if unsupported language', async () => {
      vi.stubGlobal('navigator', { language: 'xx-XX' });
      await initI18n();
      expect(t('test_key')).toBe('translated_in_en');
    });
  });

  describe('cycleLanguage', () => {
    it('cycles through languages', async () => {
      window.history.pushState({}, '', '/?lang=en');
      await initI18n();
      expect(t('test_key')).toBe('translated_in_en');
      
      cycleLanguage();
      // Should move to the next language in ['en', 'es', 'fr', 'ru', 'zh', 'ar']
      expect(t('test_key')).toBe('translated_in_es');
      
      cycleLanguage();
      expect(t('test_key')).toBe('translated_in_fr');
    });
  });

  describe('t', () => {
    it('replaces template variables', async () => {
      window.history.pushState({}, '', '/?lang=en');
      vi.stubGlobal('fetch', vi.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve([{ id: 'test_var', translation: 'Slide {{.Current}} of {{.Total}}' }])
        });
      }));
      await initI18n();
      
      expect(t('test_var', { Current: 1, Total: 5 })).toBe('Slide 1 of 5');
    });

    it('returns key if translation not found', async () => {
      await initI18n();
      expect(t('missing_key')).toBe('missing_key');
    });
  });
});
