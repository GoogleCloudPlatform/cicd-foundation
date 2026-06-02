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
import { state, SBOMManifest } from "../types";
import { setupMockDOM, createMockResponse } from "./helpers";
import {
  loadSBOM,
  viewFullLicenseText,
  renderComponentDetails,
  renderLicenseList,
  backToLicenseList,
  backToComponentDetails,
} from "../sbom_module";

describe("SBOM Module", () => {
  beforeEach(() => {
    setupMockDOM();
    state.localeHashes = {};
    global.fetch = vi.fn() as unknown as typeof fetch;
    window.applyTranslations = vi.fn();
  });

  test("loadSBOM populates state and renders", async () => {
    const mockManifest: SBOMManifest = {
      metadata: {},
      licenses: {
        MIT: { name: "MIT License", url: "", localText: "" },
      },
      components: [
        {
          name: "Test",
          version: "1.0",
          group: "G",
          licenseId: "MIT",
          supplier: "S",
          url: "",
          repository: "",
        },
      ],
    };
    (global.fetch as vi.MockedFunction<typeof fetch>).mockResolvedValue(
      createMockResponse(mockManifest),
    );

    await loadSBOM();

    expect(state.sbom).toBeDefined();
    const list = document.getElementById("license-list-container");
    expect(list?.innerHTML).toContain("Test");
  });

  test("renderComponentDetails applies Unsplash special labels", () => {
    state.sbom = {
      metadata: {},
      licenses: {
        Unsplash: { name: "Unsplash License", url: "", localText: "" },
      },
      components: [
        {
          name: "Asset",
          version: "N/A",
          group: "G",
          licenseId: "Unsplash",
          supplier: "Artist Name",
          url: "http://photo",
          repository: "http://profile",
        },
      ],
    } as SBOMManifest;

    renderComponentDetails("Asset");

    const details = document.getElementById("component-details")!;
    expect(details.innerHTML).toContain("Author");
    expect(details.innerHTML).toContain("Photo Page");
    expect(details.innerHTML).toContain("Author Profile");
    expect(details.innerHTML).toContain("Artist Name");
  });

  test("viewFullLicenseText updates viewer", async () => {
    state.sbom = {
      metadata: {},
      licenses: {
        MIT: { name: "MIT License", url: "", localText: "mit.txt" },
      },
      components: [
        {
          name: "MIT",
          version: "1.0",
          supplier: "S",
          licenseId: "MIT",
          repository: "",
          url: "",
          group: "",
          licenseFile: "mit.txt",
        },
      ],
    } as SBOMManifest;

    (global.fetch as vi.MockedFunction<typeof fetch>).mockResolvedValue(
      createMockResponse("FULL TEXT"),
    );

    await viewFullLicenseText("MIT");

    const content = document.getElementById("license-text-content");
    expect(content?.textContent).toBe("FULL TEXT");
  });

  test("renderLicenseList shows loading if sbom is null", () => {
    state.sbom = null;
    const container = document.getElementById("license-list-container");
    if (container) container.innerHTML = "";
    renderLicenseList();
    expect(container?.innerHTML).toContain("Loading software manifest");
  });

  test("viewFullLicenseText handles fetch error and non-ok response", async () => {
    state.sbom = {
      metadata: {},
      licenses: { MIT: { name: "MIT", url: "", localText: "mit.txt" } },
      components: [
        {
          name: "C",
          version: "1",
          supplier: "S",
          licenseId: "MIT",
          url: "",
          repository: "",
          group: "",
        },
      ],
    } as SBOMManifest;

    const textContainer = document.getElementById("license-text-content");

    (global.fetch as vi.Mock).mockResolvedValue({ ok: false });
    await viewFullLicenseText("C");
    expect(textContainer?.textContent).toBe("error loading license");

    (global.fetch as vi.Mock).mockRejectedValue(new Error("Network"));
    await viewFullLicenseText("C");
    expect(textContainer?.textContent).toBe("network error");
  });

  test("viewFullLicenseText early returns", async () => {
    await viewFullLicenseText("NonExistent");

    state.sbom = {
      metadata: {},
      licenses: { MIT: { name: "MIT", url: "", localText: "" } },
      components: [
        {
          name: "C",
          version: "1",
          supplier: "S",
          licenseId: "MIT",
          url: "",
          repository: "",
          group: "",
        },
      ],
    } as SBOMManifest;
    await viewFullLicenseText("C");

    state.sbom = {
      ...state.sbom,
      licenses: {
        ...state.sbom.licenses,
        MIT: { ...state.sbom.licenses["MIT"], localText: "mit.txt" },
      },
    };
    document.getElementById("license-list-container")?.remove();
    await viewFullLicenseText("C");
  });
  test("loadSBOM error", async () => {
    window.fetch = vi.fn().mockRejectedValue(new Error("err"));
    await loadSBOM();
  });
  test("loadSBOM ok", async () => {
    window.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ metadata: {}, licenses: {}, components: [] }),
    });
    await loadSBOM();
  });
  test("renderLicenseList missing div", () => {
    state.sbom = {
      metadata: {},
      licenses: {},
      components: [
        {
          name: "a",
          version: "1",
          group: "",
          licenseId: "b",
          supplier: "s",
          url: "u",
          repository: "r",
        },
      ],
    };
    document.body.innerHTML = '<div id="license-list-container"></div>';
    const origCreate = document.createElement;
    document.createElement = vi.fn().mockImplementation((tag) => {
      const el = origCreate.call(document, tag);
      if (tag === "div") {
        el.querySelector = () => null; // Mock missing inner div
      }
      return el;
    });
    renderLicenseList();
    document.createElement = origCreate;
  });
  test("renderComponentDetails unsplash", () => {
    document.body.innerHTML =
      '<div id="license-list-container"></div><div id="component-details"></div>';
    state.sbom = {
      metadata: {},
      licenses: { Unsplash: { name: "Unsplash", url: "", localText: "" } },
      components: [
        {
          name: "test",
          version: "1",
          group: "g",
          licenseId: "Unsplash",
          supplier: "s",
          url: "u",
          repository: "r",
          licenseFile: "l",
        },
      ],
    };
    renderComponentDetails("test");
  });
  test("renderComponentDetails missing detailsContainer", () => {
    document.body.innerHTML = '<div id="license-list-container"></div>';
    state.sbom = {
      metadata: {},
      licenses: {},
      components: [
        {
          id: "a",
          name: "Lib",
          version: "1",
          supplier: "Dev",
          licenseId: "MIT",
          url: "http",
          repository: "http",
        } as any,
      ],
    };
    renderComponentDetails("Lib"); // should return early
  });
  test("viewFullLicenseText missing viewerContainer or textContainer", async () => {
    state.sbom = {
      metadata: {},
      components: [
        {
          id: "c",
          name: "Comp",
          version: "1.0",
          supplier: "S",
          licenseId: "MIT",
          url: "",
          repository: "",
        } as any,
      ],
      licenses: {
        MIT: { name: "MIT License", localText: "path/to/mit.txt", url: "" },
      },
    };
    document.body.innerHTML =
      '<div id="license-list-container"></div><div id="component-details"></div>';
    await viewFullLicenseText("Comp");
    document.body.innerHTML =
      '<div id="license-list-container"></div><div id="component-details"></div><div id="license-viewer"></div>';
    await viewFullLicenseText("Comp");
  });
  test("viewFullLicenseText fetch resolves but not ok", async () => {
    state.sbom = {
      metadata: {},
      components: [
        {
          id: "c",
          name: "Comp",
          version: "1.0",
          supplier: "S",
          licenseId: "MIT",
          url: "",
          repository: "",
        } as any,
      ],
      licenses: {
        MIT: { name: "MIT License", localText: "path/to/mit.txt", url: "" },
      },
    };
    document.body.innerHTML = `
          <div id="license-list-container"></div><div id="component-details"></div>
          <div id="license-viewer"></div><div id="license-text-content"></div>
        `;
    window.fetch = vi.fn(() =>
      Promise.resolve({ ok: false, text: () => Promise.resolve("") }),
    ) as any;
    await viewFullLicenseText("Comp");
  });
  test("viewFullLicenseText handles missing component or licenseInfo", async () => {
    state.sbom = { metadata: {}, components: [], licenses: {} };
    await viewFullLicenseText("Comp");

    state.sbom = {
      ...state.sbom,
      components: [
        {
          id: "c",
          name: "Comp",
          version: "1.0",
          supplier: "S",
          licenseId: "MIT",
          url: "",
          repository: "",
        } as any,
      ],
    };
    await viewFullLicenseText("Comp"); // Missing license
  });
  test("viewFullLicenseText ok", async () => {
    document.body.innerHTML =
      '<div id="license-list-container"></div><div id="component-details"></div><div id="license-viewer"></div><div id="license-text-content"></div>';
    state.sbom = {
      metadata: {},
      licenses: { l: { name: "l", url: "l", localText: "/l.txt" } },
      components: [
        {
          name: "test",
          version: "1",
          group: "g",
          licenseId: "l",
          supplier: "s",
          url: "u",
          repository: "r",
        },
      ],
    };
    window.fetch = vi
      .fn()
      .mockResolvedValue({ ok: true, text: async () => "text" });
    await viewFullLicenseText("test");

    window.fetch = vi.fn().mockResolvedValue({ ok: false });
    await viewFullLicenseText("test");
  });
  test("back to license list and details", () => {
    document.body.innerHTML =
      '<div id="license-list-container"></div><div id="component-details"></div><div id="license-viewer"></div>';
    backToLicenseList();
    backToComponentDetails();
  });
  test("sbom_module renderComponentDetails Unsplash case", () => {
    state.sbom = {
      metadata: {},
      components: [
        {
          id: "comp1",
          name: "Photo",
          version: "1.0",
          supplier: "Jane Doe",
          licenseId: "Unsplash",
          url: "http",
          repository: "http",
        } as any,
        {
          id: "comp2",
          name: "Other",
          version: "1.0",
          supplier: "John Doe",
          licenseId: "MIT",
          url: "http",
          repository: "http",
        } as any,
      ],
      licenses: {
        Unsplash: {
          name: "Unsplash License",
          localText: "path/to/unsplash.txt",
          url: "",
        },
        MIT: { name: "MIT License", localText: "path/to/mit.txt", url: "" },
      },
    };

    document.body.innerHTML = `
      <div id="license-list-container"></div>
      <div id="component-details"></div>
    `;
    renderComponentDetails("Photo");
    const details = document.getElementById("component-details");
    expect(details?.innerHTML).toContain("Author Profile");

    // Test the regular supplier branch
    renderComponentDetails("Other");
    expect(details?.innerHTML).toContain("Supplier");
  });
  test("sbom_module renderComponentDetails handles missing data", () => {
    document.body.innerHTML = `
      <div id="license-list-container"></div>
      <div id="component-details"></div>
    `;
    state.sbom = null;
    renderComponentDetails("non-existent");
    state.sbom = { metadata: {}, components: [], licenses: {} };
    renderComponentDetails("non-existent");
  });
  test("sbom_module renderComponentDetails handles missing elements", () => {
    state.sbom = {
      metadata: {},
      components: [
        {
          id: "comp1",
          name: "Lib",
          version: "1",
          supplier: "Dev",
          licenseId: "MIT",
          url: "http",
          repository: "http",
        } as any,
      ],
      licenses: {},
    };
    document.body.innerHTML = "";
    renderComponentDetails("Lib"); // should return early
  });
  test("sbom_module renderLicenseList missing container", () => {
    document.body.innerHTML = "";
    renderLicenseList(); // returns early
  });
  test("sbom_module viewFullLicenseText fetch error handling", async () => {
    setupMockDOM();
    state.sbom = {
      metadata: {},
      components: [
        {
          id: "c",
          name: "Comp",
          version: "1.0",
          supplier: "S",
          licenseId: "MIT",
          url: "",
          repository: "",
        } as any,
      ],
      licenses: {
        MIT: { name: "MIT License", localText: "path/to/mit.txt", url: "" },
      },
    };
    global.fetch = vi.fn(() => Promise.reject("Network Error"));
    await viewFullLicenseText("Comp");
    expect(
      document.getElementById("license-text-content")?.textContent,
    ).toContain("network error");
  });
});
