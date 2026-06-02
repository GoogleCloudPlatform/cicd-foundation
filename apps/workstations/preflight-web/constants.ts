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

export const CONFIG_KEY = "cws_preflight_config";
export const DEFAULT_RETRY_INTERVAL_MS = 1000;
export const MAX_BACKOFF_INTERVAL_MS = 30000;
export const PROGRESS_RING_CIRCUMFERENCE = 282.7;

export const APP_STATUS_HEADER = "x-app-status";
export const APP_STATUS_STARTING = "STARTING";

/**
 * Generates the Guacamole client path for a specific protocol.
 * The identifier is a base64 encoded string: "<connection_name>\0c\0default"
 * @param protocol The protocol name (e.g., 'RDP', 'SSH').
 */
export function getGuacamoleUrl(protocol: string): string {
  const name = protocol.toUpperCase();
  // Guacamole client identifiers are base64(name + \0 + 'c' + \0 + 'default')
  // We use btoa for the conversion and strip padding.
  const raw = `${name}\0c\0default`;
  const encoded = btoa(raw).replace(/=+$/, "");
  return `/guacamole/#/client/${encoded}`;
}

/**
 * Helper to get the full localized name of a connection protocol.
 */
export function getProtocolFullName(proto: string): string {
  const labels: Record<string, string> = {
    rdp: "label_protocol_rdp",
    ssh: "label_protocol_ssh",
    vnc: "label_protocol_vnc",
  };
  const key = labels[proto.toLowerCase()];
  return key && window.t
    ? window.t(key, proto.toUpperCase())
    : proto.toUpperCase();
}
