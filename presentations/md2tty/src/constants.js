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

/** @fileoverview Shared constants for the presentation viewer. */

export const INITIAL_FONT_SIZE = 20;
export const SCALE_MARGIN = 0.95;
export const THEME_FLASH_DURATION_MS = 200;
export const RESIZE_DEBOUNCE_MS = 200;

import { t } from './i18n.js';

/** @enum {string} */
export const Selectors = {
  TARGET: 'render-target',
  FOOTER: 'footer',
  OVERLAY: 'shortcuts-overlay',
  MEASURE_CONTAINER: 'measure-container',
};

/** @enum {string} */
export const Themes = {
  LIGHT: 'light-theme',
  FLASH: 'theme-flash',
};

export const getHelpMarkdown = () => `
# ${t('about_md2tty_js')}

${t('about_md2tty')}
[https://github.com/GoogleCloudPlatform/cicd-foundation/tree/main/presentations/md2tty](https://github.com/GoogleCloudPlatform/cicd-foundation/tree/main/presentations/md2tty)

&nbsp;

# ${t('shortcuts')}

| **${t('key')}** | **${t('action')}** | **${t('key')}** | **${t('action')}** |
|:---|:---|:---|:---|
| \`j\`, \`n\`, \`s\`, \`→\` | ${t('next_slide')} | \`k\`, \`p\`, \`w\`, \`←\` | ${t('previous_slide')} |
| \`PageDown\` | ${t('next_slide')} | \`PageUp\` | ${t('previous_slide')} |
| \`Home\` | ${t('first_slide')} | \`End\` | ${t('last_slide')} |
| \`1\` - \`9\` | ${t('jump_to_slide')} | \`t\` | ${t('toggle_theme')} |
| \`f\` | ${t('toggle_flash')} | \`l\` | ${t('toggle_language')} |
| \`q\` | ${t('quit')} | \`h\`, \`?\` | ${t('help')} |
`;
