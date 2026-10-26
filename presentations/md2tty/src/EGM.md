<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Browser Presentation Engine (`presentations/md2tty/src`)

## Overview

Client-side JavaScript presentation engine (`md2tty`) that loads Markdown slides
from a JSON manifest and renders them into a terminal-styled DOM interface with
dynamic viewport font scaling, multi-language localization (`i18n`), theme
toggling and flashing, and keyboard/click navigation.

## Interface

- `constants.js`:
  - `INITIAL_FONT_SIZE` (`number = 20`)
  - `SCALE_MARGIN` (`number = 0.95`)
  - `THEME_FLASH_DURATION_MS` (`number = 200`)
  - `RESIZE_DEBOUNCE_MS` (`number = 200`)
  - `Selectors` (`enum { TARGET, FOOTER, OVERLAY, MEASURE_CONTAINER }`)
  - `Themes` (`enum { LIGHT, FLASH }`)
  - `getHelpMarkdown() -> string`
- `i18n.js`:
  - `initI18n() -> Promise<void>`
  - `cycleLanguage() -> void`
  - `t(key: string, params?: Record<string, string|number>) -> string`
- `md2tty.js`:
  - `class Md2tty { constructor(options?: { target?: string|HTMLElement,
manifestUrl?: string, slidesDir?: string }), init(): Promise<void>,
mount(): void, unmount(): void, autoScale(): void, goTo(index: number):
void, next(): void, prev(): void, toggleHelp(show?: boolean): void }`
- `scaling.js`:
  - `autoScale(slideContents: Array<string>, target: HTMLElement,
measureContainer: HTMLElement, viewportW?: number, viewportH?: number)
-> void`
- `slides.js`:
  - `setTabTitle(slideContents: Array<string>) -> void`
  - `renderAllSlides(container: HTMLElement, slideNames: Array<string>,
slideContents: Array<string>) -> void`
  - `activateSlide(index: number, container: HTMLElement, flash?: boolean)
-> number`
  - `initSlides(manifestUrl?: string, slidesDir?: string) -> Promise<{
names: Array<string>, contents: Array<string> }>`
  - `updateAllFooters(container: HTMLElement, totalSlides: number) -> void`
- `ui.js`:
  - `updateFooter(footer: HTMLElement, current: number, total: number) ->
void`
  - `renderHelp(overlay: HTMLElement, current: number, total: number) ->
void`
  - `toggleHelp(overlay: HTMLElement, show?: boolean) -> boolean`
  - `toggleTheme() -> void`
  - `flashTheme() -> void`

## Invariants

- Supported languages are fixed to `['en', 'es', 'fr', 'ru', 'zh', 'ar']`,
  defaulting to index `0` (`'en'`) if the URL `lang` parameter or
  `navigator.language` prefix is unsupported.
- Translation lookup in `t()` falls back to the `'en'` dictionary and then to
  the raw key string if a translation is missing.
- Slide navigation in `activateSlide()` clamps the active slide index to `[0,
slides.length - 1]`, and URL hash values are 1-indexed (`#1` corresponds to
  slide index `0`).
- Dynamic font scaling in `autoScale()` measures content at a base of
  `INITIAL_FONT_SIZE` (`20px`) with `maxWidth` `'80ch'` (plus `60px` width
  buffer and `100px` height buffer), applies `SCALE_MARGIN` (`0.95`), and
  enforces a minimum `--base-font-size` of `10px`.
- Print layout scaling in `Md2tty` `beforeprint` uses fixed dimensions of
  `1056x793` pixels.

## Side Effects

- `slides.js` configures global `marked` options (`breaks: true, gfm: true`)
  at module import time.
- `initI18n()` performs network `fetch()` requests for all 6 locale JSON files
  under `locales/<lang>.json` and mutates module-level `translations` state.
- `initSlides()` performs network `fetch()` requests for the manifest URL
  (default `'slides.json'`) and all listed slide Markdown files.
- Mutates DOM elements across `document.title`, `document.body.classList`
  (`'light-theme'`), `document.documentElement.style` (`'--base-font-size'`),
  slide container `innerHTML`/classes, help overlay, and `measureContainer`.
- `activateSlide()` mutates browser history state via
  `history.replaceState(null, '', '#<index + 1>')`.
- `Md2tty.mount()` and `unmount()` attach and detach global `window` event
  listeners for `'keydown'`, `'click'`, `'resize'`, `'beforeprint'`, and
  `'afterprint'`.
- `flashTheme()` schedules an asynchronous theme toggle via `setTimeout(...,
THEME_FLASH_DURATION_MS)`.
- Pressing `'q'` or `'Q'` invokes `window.close()` and replaces the target
  container's `innerHTML` with a termination message.
