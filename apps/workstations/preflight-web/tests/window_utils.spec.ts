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

import { vi } from "vitest";
import { windowUtils } from "../window_utils";

describe("windowUtils", () => {
  const originalLocation = window.location;

  beforeEach(() => {
    // Reset location
    window.history.pushState({}, "", "/");
  });

  afterEach(() => {
    (window as any).location = originalLocation;
    vi.restoreAllMocks();
  });

  test("search getter", () => {
    window.history.pushState({}, "Test Title", "/test-path?test=1");
    expect(windowUtils.search).toBe("?test=1");
  });

  test("origin getter", () => {
    expect(windowUtils.origin).toBe(window.location.origin);
  });

  test("pathname getter", () => {
    window.history.pushState({}, "Test Title", "/test-path?test=1");
    expect(windowUtils.pathname).toBe("/test-path");
  });

  test("assign", () => {
    delete (window as any).location;
    window.location = { ...originalLocation, assign: vi.fn() } as any;
    windowUtils.assign("http://example.com");
    expect(window.location.assign).toHaveBeenCalledWith("http://example.com");
  });

  test("reload", () => {
    delete (window as any).location;
    window.location = { ...originalLocation, reload: vi.fn() } as any;
    windowUtils.reload();
    expect(window.location.reload).toHaveBeenCalled();
  });

  test("href setter", () => {
    // jsdom navigation works by updating the hash without error.
    windowUtils.href = "#foo";
    expect(window.location.href.endsWith("#foo")).toBe(true);
  });
});
