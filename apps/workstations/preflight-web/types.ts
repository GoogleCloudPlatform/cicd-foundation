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
  // go/keep-sorted start
  readonly autoRedirect: boolean;
  readonly clientIp: string;
  readonly clusterName?: string;
  readonly configName?: string;
  readonly connectionId: string;
  readonly connectionTypes: ReadonlyArray<string>;
  readonly hasGuacamole?: boolean;
  readonly hasJetbrainsGateway?: boolean;
  readonly hostSshPort?: string;
  readonly hostname: string;
  readonly lang: string;
  readonly projectId?: string;
  readonly redirectUrl: string;
  readonly region?: string;
  readonly retryIntervalMs: number;
  readonly showDebug: boolean;
  readonly sshPort?: number;
  readonly timeoutMs: number;
  // go/keep-sorted end
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
  // go/keep-sorted start
  readonly checkInterval: number | null;
  readonly config: AppConfig;
  readonly currentInterval: number;
  readonly currentModal: string | null;
  readonly isHealthy: boolean;
  readonly lastStatus: string | null;
  readonly latencyMs: number | null;
  readonly localeHashes: Record<string, string>;
  readonly pollCount: number;
  readonly previousModal: string | null;
  readonly sbom: SBOMManifest | null;
  readonly simulateSec: number;
  readonly startTime: number;
  readonly timerInterval: number | null;
  readonly translations: Record<string, TranslationSet>;
  readonly uiTransient: unknown | null;
  // go/keep-sorted end
}

/**
 * Default application configuration.
 */
export const DEFAULT_CONFIG: AppConfig = {
  // go/keep-sorted start
  autoRedirect: true,
  clientIp: "0.0.0.0",
  clusterName: "",
  configName: "",
  connectionId: "RDP",
  connectionTypes: ["RDP", "SSH"],
  hasGuacamole: true,
  hasJetbrainsGateway: false,
  hostSshPort: "",
  hostname: "",
  lang: "en",
  projectId: "",
  redirectUrl: "",
  region: "",
  retryIntervalMs: 1000,
  showDebug: false,
  sshPort: 22,
  timeoutMs: 200000,
  // go/keep-sorted end
};

/**
 * The singleton state instance for the application.
 */
export const state: AppState = {
  // go/keep-sorted start
  checkInterval: null,
  config: { ...DEFAULT_CONFIG },
  currentInterval: 1000,
  currentModal: null,
  isHealthy: false,
  lastStatus: null,
  latencyMs: null,
  localeHashes: {},
  pollCount: 0,
  previousModal: null,
  sbom: null,
  simulateSec: 0,
  startTime: Date.now(),
  timerInterval: null,
  translations: {},
  uiTransient: null,
  // go/keep-sorted end
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
    // go/keep-sorted start
    applyTranslations: () => void;
    backToComponentDetails: () => void;
    backToLicenseList: () => void;
    checkHealth: () => void;
    closeAllModals: () => void;
    closeModal: (id: string) => void;
    copySettingsUrl: () => void;
    fetchTranslations: (lang: string) => Promise<void>;
    filterLanguages: () => void;
    handleHealthSuccess: () => void;
    loadLocaleHashes: () => Promise<void>;
    loadSBOM: () => Promise<void>;
    manualConnect: () => void;
    openModal: (id: string) => void;
    renderConnectionTypeList: () => void;
    renderLanguageList: () => void;
    reportBug: () => void;
    resetConfig: () => void;
    resetUIVisuals: () => void;
    saveConfig: () => void;
    startHealthChecks: () => void;
    syncRetryIntervalState: () => void;
    t: (key: string, def: string) => string;
    toggleDebug: () => void;
    toggleRetry: () => void;
    updateConfig: () => void;
    updateDebugInfo: () => void;
    updateDisplayData: () => void;
    updateStatusMessage: () => void;
    updateTimer: () => void;
    updateUIFromConfig: () => void;
    viewFullLicenseText: (name: string) => void;
    // go/keep-sorted end
    CWS_CONFIG?: {
      // go/keep-sorted start
      autoRedirect?: boolean;
      clientIp?: string;
      clusterName?: string;
      configName?: string;
      connectionId?: string;
      hasGuacamole?: boolean;
      hasJetbrainsGateway?: boolean;
      hostSshPort?: string;
      hostname?: string;
      projectId?: string;
      redirectUrl?: string;
      region?: string;
      serverLang?: string;
      sshPort?: number;
      supportedProtocols?: string[];
      timeoutMs?: number;
      // go/keep-sorted end
    };
  }
}
