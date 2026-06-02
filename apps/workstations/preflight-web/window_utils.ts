/**
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

export const windowUtils = {
  get search(): string {
    return window.location.search;
  },
  get origin(): string {
    return window.location.origin;
  },
  get pathname(): string {
    return window.location.pathname;
  },
  assign(url: string | URL): void {
    window.location.assign(url);
  },
  reload(): void {
    window.location.reload();
  },
  set href(url: string) {
    window.location.href = url;
  },
};
