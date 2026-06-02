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

import { ComponentInfo, LicenseInfo, state, updateState } from "./types";

/**
 * Interface representing the raw SBOM structure from the JSON file.
 * Uses snake_case to match the source file format.
 */
interface RawSBOM {
  readonly metadata: Record<string, unknown>;
  readonly licenses: Record<
    string,
    {
      readonly name: string;
      readonly url: string;
      readonly local_text: string;
    }
  >;
  readonly components: ReadonlyArray<{
    readonly name: string;
    readonly version: string;
    readonly group: string;
    readonly license_id: string;
    readonly supplier: string;
    readonly url: string;
    readonly repository: string;
    readonly description?: string;
    readonly licenseFile?: string;
  }>;
}

/**
 * Loads the Software Bill of Materials (SBOM) from the static server artifact and transforms it.
 */
export async function loadSBOM(): Promise<void> {
  try {
    const response = await fetch("/sbom.json");
    if (response.ok) {
      const raw = (await response.json()) as RawSBOM;

      // Transform raw snake_case data to camelCase interfaces
      const licenses: Record<string, LicenseInfo> = {};
      for (const [id, info] of Object.entries(raw.licenses)) {
        licenses[id] = {
          name: info.name,
          url: info.url,
          localText: info.local_text,
        };
      }

      const components: ComponentInfo[] = raw.components.map((comp) => ({
        name: comp.name,
        version: comp.version,
        group: comp.group,
        licenseId: comp.license_id,
        supplier: comp.supplier,
        url: comp.url,
        repository: comp.repository,
        description: comp.description,
        licenseFile: comp.licenseFile,
      }));

      updateState({
        sbom: {
          metadata: raw.metadata,
          licenses,
          components,
        },
      });

      renderLicenseList();
    }
  } catch (e) {
    console.error("failed to load SBOM", e);
  }
}

/**
 * Renders the list of software components grouped by their architectural group.
 */
export function renderLicenseList(): void {
  const container = document.getElementById("license-list-container");
  if (!container) return;

  if (!state.sbom) {
    const loadingText =
      window.t?.("label_loading_manifest", "Loading software manifest...") ||
      "Loading software manifest...";
    container.innerHTML = `<p class="text-secondary animate-pulse p-8 uppercase tracking-widest text-center">${loadingText}</p>`;
    return;
  }

  container.innerHTML = "";

  const groups: Record<string, ComponentInfo[]> = {};
  state.sbom.components.forEach((comp: ComponentInfo) => {
    const groupName = comp.group || "Miscellaneous";
    if (!groups[groupName]) {
      groups[groupName] = [];
    }
    groups[groupName].push(comp);
  });

  const groupNames = Object.keys(groups).sort();

  groupNames.forEach((groupName) => {
    const section = document.createElement("div");
    section.className = "mb-8";
    section.innerHTML = `<h3 class="ui-label mb-3 text-secondary opacity-80">${groupName.toUpperCase()}</h3><div class="space-y-3"></div>`;
    const list = section.querySelector("div");
    if (!list) return;

    const groupComponents = groups[groupName];
    if (groupComponents) {
      groupComponents.forEach((comp: ComponentInfo) => {
        const license =
          state.sbom?.licenses[comp.licenseId]?.name || comp.licenseId;
        const item = document.createElement("button");
        item.className =
          "w-full text-left p-4 rounded-lg bg-white/5 border border-neutral-800 hover:border-secondary transition-all group";
        item.onclick = (): void => renderComponentDetails(comp.name);
        item.innerHTML = `
          <div class="flex justify-between items-start">
            <div class="flex flex-col">
              <span class="text-sm font-bold text-white group-hover:text-secondary transition-colors">${comp.name}</span>
              <span class="text-[10px] text-on-surface-variant uppercase tracking-widest">${license}</span>
            </div>
            <span class="material-symbols-outlined text-on-surface-variant group-hover:text-secondary transition-colors">chevron_right</span>
          </div>
        `;
        list.appendChild(item);
      });
    }
    container.appendChild(section);
  });
}

/**
 * Renders the deep-dive details for a specific component.
 * Features dedicated Version, License, Supplier, and Contextual Link sections.
 * @param name The name of the component to display.
 */
export function renderComponentDetails(name: string): void {
  const comp = state.sbom?.components.find((c) => c.name === name);
  const listContainer = document.getElementById("license-list-container");
  const detailsContainer = document.getElementById("component-details");
  if (!comp || !listContainer || !detailsContainer) return;

  const licenseInfo = state.sbom?.licenses[comp.licenseId];
  const licenseName = licenseInfo?.name || comp.licenseId;
  const licenseFile = licenseInfo?.localText;

  // Handle Unsplash Special Case Labels
  const isUnsplash = comp.licenseId === "Unsplash";
  const supplierLabel = isUnsplash
    ? window.t?.("label_artist", "Author") || "Author"
    : window.t?.("label_supplier", "Supplier") || "Supplier";
  const urlLabel = isUnsplash
    ? window.t?.("link_asset", "Photo Page") || "Photo Page"
    : window.t?.("link_homepage", "Project Website") || "Project Website";
  const repoLabel = isUnsplash
    ? window.t?.("link_artist", "Author Profile") || "Author Profile"
    : window.t?.("link_repository", "Source Repository") || "Source Repository";

  listContainer.classList.add("hidden");
  detailsContainer.classList.remove("hidden");
  detailsContainer.innerHTML = `
    <button class="ui-btn-ghost mb-6" id="btn-back-to-license-list">
      <span class="material-symbols-outlined text-sm">arrow_back</span> <span>BACK TO LIST</span>
    </button>
    <div class="space-y-8">
      <div>
        <h3 class="ui-label mb-1">Component</h3>
        <p class="text-xl font-bold text-white">${comp.name}</p>
      </div>

      <div class="grid grid-cols-2 gap-6">
        <div>
          <h3 class="ui-label mb-1">Version</h3>
          <p class="text-sm text-white font-mono uppercase tracking-wider">${
            comp.version
          }</p>
        </div>
        <div>
          <h3 class="ui-label mb-1">License</h3>
          <p class="text-sm text-white uppercase tracking-wider">${licenseName}</p>
        </div>
      </div>

      <div>
        <h3 class="ui-label mb-1">${supplierLabel}</h3>
        <p class="text-sm text-on-surface-variant uppercase tracking-widest">${
          comp.supplier
        }</p>
      </div>

      <div>
        <h3 class="ui-label mb-3">Project Links</h3>
        <div class="space-y-3">
          <a href="${
            comp.url
          }" target="_blank" class="flex items-center justify-between p-3 rounded bg-white/5 border border-neutral-800 hover:border-secondary transition-all group">
            <span class="text-xs font-bold text-white group-hover:text-secondary transition-colors">${urlLabel}</span>
            <span class="material-symbols-outlined text-sm text-on-surface-variant group-hover:text-secondary transition-colors">open_in_new</span>
          </a>
          <a href="${
            comp.repository
          }" target="_blank" class="flex items-center justify-between p-3 rounded bg-white/5 border border-neutral-800 hover:border-secondary transition-all group">
            <span class="text-xs font-bold text-white group-hover:text-secondary transition-colors">${repoLabel}</span>
            <span class="material-symbols-outlined text-sm text-on-surface-variant group-hover:text-secondary transition-colors">code</span>
          </a>
        </div>
      </div>

      ${
        licenseFile
          ? `
        <button class="ui-btn-action w-full" id="btn-view-full-license">
          VIEW FULL LICENSE TEXT
        </button>
      `
          : ""
      }
    </div>
  `;

  document
    .getElementById("btn-back-to-license-list")
    ?.addEventListener("click", () => backToLicenseList());
  document
    .getElementById("btn-view-full-license")
    ?.addEventListener("click", () => {
      void viewFullLicenseText(comp.name);
    });
}

/**
 * Fetches and displays the full license text for a specific component.
 * @param componentName The name of the component.
 */
export async function viewFullLicenseText(
  componentName: string,
): Promise<void> {
  const component = state.sbom?.components.find(
    (c) => c.name === componentName,
  );
  if (!component) return;

  const licenseInfo = state.sbom?.licenses[component.licenseId];
  if (!licenseInfo || !licenseInfo.localText) return;

  const listContainer = document.getElementById("license-list-container");
  const detailsContainer = document.getElementById("component-details");
  const viewerContainer = document.getElementById("license-viewer");
  const textContainer = document.getElementById("license-text-content");

  if (!listContainer || !detailsContainer || !viewerContainer || !textContainer)
    return;

  listContainer.classList.add("hidden");
  detailsContainer.classList.add("hidden");
  viewerContainer.classList.remove("hidden");

  textContainer.textContent =
    (window.t?.("msg_loading_license", "Loading license for...") ||
      "Loading...") + ` ${componentName}...`;

  try {
    const response = await fetch(licenseInfo.localText);
    if (response.ok) {
      textContainer.textContent = await response.text();
    } else {
      textContainer.textContent =
        window.t?.("msg_error_load_license", "error loading license") ||
        "error";
    }
  } catch (e) {
    textContainer.textContent =
      window.t?.("msg_error_network_license", "network error") ||
      "network error";
  }
}

/**
 * Navigates back to the main license list view.
 */
export function backToLicenseList(): void {
  document.getElementById("license-list-container")?.classList.remove("hidden");
  document.getElementById("component-details")?.classList.add("hidden");
  document.getElementById("license-viewer")?.classList.add("hidden");
}

/**
 * Navigates back to the specific component details view.
 */
export function backToComponentDetails(): void {
  document.getElementById("license-list-container")?.classList.add("hidden");
  document.getElementById("component-details")?.classList.remove("hidden");
  document.getElementById("license-viewer")?.classList.add("hidden");
}
