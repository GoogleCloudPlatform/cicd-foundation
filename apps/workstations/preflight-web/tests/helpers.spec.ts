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
import { createMockResponse, setupMockDOM } from "./helpers";
import { logInfo } from "../types";

describe("helpers", () => {
  test("logInfo prints to console", () => {
    const consoleSpy = vi.spyOn(console, "log").mockImplementation(() => {});
    logInfo("Test");
    expect(consoleSpy).toHaveBeenCalledWith("[CWS] Test");
    consoleSpy.mockRestore();
  });

  describe("createMockResponse", () => {
    test("handles blob response correctly", async () => {
      const response = createMockResponse("test data");
      const blob = await response.blob();
      const buffer = await blob.arrayBuffer();
      const text = await blob.text();

      expect(buffer).toBeInstanceOf(ArrayBuffer);
      expect(text).toBe("test data"); // Not stringified because it's a string
    });

    test("handles text string response correctly", async () => {
      const response = createMockResponse("string data");
      const blob = await response.blob();
      const text = await blob.text();
      expect(text).toBe("string data");
    });
  });

  describe("setupMockDOM", () => {
    test("initializes mock history and navigator", () => {
      setupMockDOM();

      expect(window.history.replaceState).toBeDefined();
      expect(navigator.clipboard.writeText).toBeDefined();

      // Call mock history replaceState
      window.history.replaceState({}, "", "");
      expect(window.history.replaceState).toHaveBeenCalled();

      // Call mock clipboard writeText
      navigator.clipboard.writeText("test");
      expect(navigator.clipboard.writeText).toHaveBeenCalled();
    });
  });
});
