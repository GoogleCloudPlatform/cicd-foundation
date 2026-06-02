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

/**
 * Configuration for the Preflight application.
 */
export interface AppConfig {
  readonly hostname: string;
  readonly uplink: string;
  readonly timeoutMs: number;
  readonly retryIntervalMs: number;
  readonly autoRedirect: boolean;
  readonly showDebug: boolean;
  readonly lang: string;
  readonly connectionId: string;
  readonly connectionTypes: ReadonlyArray<string>;
  readonly clientIp: string;
}

/**
 * Information about a software component in the SBOM.
 */
export interface ComponentInfo {
  readonly name: string;
  readonly version: string;
  readonly group: string;
  readonly licenseId: string;
  readonly supplier: string;
  readonly url: string;
  readonly repository: string;
  readonly description?: string;
  readonly licenseFile?: string;
}

/**
 * Information about a license in the SBOM.
 */
export interface LicenseInfo {
  readonly name: string;
  readonly url: string;
  readonly localText: string;
}

/**
 * Software Bill of Materials manifest structure.
 */
export interface SBOMManifest {
  readonly metadata: Record<string, unknown>;
  readonly licenses: Record<string, LicenseInfo>;
  readonly components: ReadonlyArray<ComponentInfo>;
}

/**
 * A set of translations for a specific language.
 */
export interface TranslationSet {
  readonly name: string;
  readonly native: string;
  readonly dict: Record<string, string>;
}

/**
 * Global application state.
 */
export interface AppState {
  readonly startTime: number;
  readonly timerInterval: number | null;
  readonly checkInterval: number | null;
  readonly config: AppConfig;
  readonly currentModal: string | null;
  readonly previousModal: string | null;
  readonly isHealthy: boolean;
  readonly simulateSec: number;
  readonly sbom: SBOMManifest | null;
  readonly translations: Record<string, TranslationSet>;
  readonly localeHashes: Record<string, string>;
  readonly latencyMs: number | null;
  readonly pollCount: number;
  readonly lastStatus: string | null;
  readonly currentInterval: number;
  readonly uiTransient: unknown | null;
}

/**
 * Default application configuration.
 */
export const DEFAULT_CONFIG: AppConfig = {
  hostname: "",
  uplink: "us-central1-a",
  timeoutMs: 200000,
  retryIntervalMs: 1000,
  autoRedirect: true,
  showDebug: false,
  lang: "en",
  connectionId: "RDP",
  connectionTypes: ["RDP", "SSH"],
  clientIp: "0.0.0.0",
};

/**
 * The singleton state instance for the application.
 */
export const state: AppState = {
  startTime: Date.now(),
  timerInterval: null,
  checkInterval: null,
  config: { ...DEFAULT_CONFIG },
  currentModal: null,
  previousModal: null,
  isHealthy: false,
  simulateSec: 0,
  sbom: null,
  translations: {},
  localeHashes: {},
  latencyMs: null,
  pollCount: 0,
  lastStatus: null,
  currentInterval: 1000,
  uiTransient: null,
};

/**
 * Updates the global state using a partial patch.
 * This helper centralizes state mutations and maintains compliance with readonly mandates.
 * @param patch The state changes to apply.
 */
export function updateState(patch: Partial<AppState>): void {
  Object.assign(state, patch);
}

/**
 * Resets the transient session state to its initial values.
 * Used during configuration updates or retry resets.
 */
export function resetSessionState(): void {
  updateState({
    startTime: Date.now(),
    isHealthy: false,
    pollCount: 0,
    lastStatus: null,
    latencyMs: null,
  });
}

/**
 * Logs an informational message to the console with a CWS prefix.
 * @param msg The message to log.
 */
export function logInfo(msg: string): void {
  console.log(`[CWS] ${msg}`);
}

declare global {
  interface Window {
    openModal: (id: string) => void;
    closeModal: (id: string) => void;
    closeAllModals: () => void;
    toggleRetry: () => void;
    toggleDebug: () => void;
    updateConfig: () => void;
    resetConfig: () => void;
    copySettingsUrl: () => void;
    backToLicenseList: () => void;
    backToComponentDetails: () => void;
    viewFullLicenseText: (name: string) => void;
    filterLanguages: () => void;
    reportBug: () => void;
    manualConnect: () => void;
    applyTranslations: () => void;
    updateUIFromConfig: () => void;
    updateDebugInfo: () => void;
    updateStatusMessage: () => void;
    startHealthChecks: () => void;
    updateTimer: () => void;
    handleHealthSuccess: () => void;
    checkHealth: () => void;
    saveConfig: () => void;
    t: (key: string, def: string) => string;
    fetchTranslations: (lang: string) => Promise<void>;
    loadLocaleHashes: () => Promise<void>;
    loadSBOM: () => Promise<void>;
    renderLanguageList: () => void;
    renderConnectionTypeList: () => void;
    updateDisplayData: () => void;
    resetUIVisuals: () => void;
    syncRetryIntervalState: () => void;
    CWS_CONFIG?: {
      hostname?: string;
      uplink?: string;
      supportedProtocols?: string[];
      serverLang?: string;
      clientIp?: string;
    };
  }
}
