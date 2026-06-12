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

/** @fileoverview i18n support */

const SUPPORTED_LANGS = ['en', 'es', 'fr', 'ru', 'zh', 'ar'];
let currentLangIndex = 0;

/** @type {Record<string, Record<string, string>>} */
const translations = {};

/**
 * Initializes i18n by fetching all supported languages upfront.
 */
export async function initI18n() {
  const urlParams = new URLSearchParams(window.location.search);
  const urlLang = urlParams.get('lang');
  const browserLang = (urlLang || navigator.language || 'en').substring(0, 2);
  currentLangIndex = SUPPORTED_LANGS.includes(browserLang) ? SUPPORTED_LANGS.indexOf(browserLang) : 0;

  const fetches = SUPPORTED_LANGS.map(lang => 
    fetch(`locales/${lang}.json`)
      .then(res => res.ok ? res.json() : [])
      .then(data => ({ lang, data }))
      .catch(e => {
        console.error(`Failed to load locale ${lang}`, e);
        return { lang, data: [] };
      })
  );

  const results = await Promise.all(fetches);
  
  for (const { lang, data } of results) {
    translations[lang] = {};
    for (const item of data) {
      translations[lang][item.id] = item.translation;
    }
  }
}

/**
 * Cycles to the next supported language.
 */
export function cycleLanguage() {
  currentLangIndex = (currentLangIndex + 1) % SUPPORTED_LANGS.length;
}

/**
 * Translates a key, replacing template variables like {{.Current}}
 * @param {string} key 
 * @param {Record<string, string|number>} params 
 * @returns {string}
 */
export function t(key, params = {}) {
  const currentLang = SUPPORTED_LANGS[currentLangIndex];
  const dict = translations[currentLang] || {};
  let str = dict[key] || (translations['en'] && translations['en'][key]) || key;
  for (const [k, v] of Object.entries(params)) {
    str = str.replace(`{{.${k}}}`, String(v));
  }
  return str;
}
