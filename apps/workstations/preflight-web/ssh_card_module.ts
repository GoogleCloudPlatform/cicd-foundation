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

import { state } from "./types";

/**
 * Copies text to the system clipboard and provides visual feedback on a target element.
 */
export async function copyToClipboard(
  text: string,
  elementId = "copy-ssh-text",
): Promise<void> {
  const flashCopied = (): void => {
    const label = document.getElementById(elementId);
    if (label) {
      if (!label.hasAttribute("data-original-text")) {
        label.setAttribute("data-original-text", label.textContent ?? "");
      }
      const originalText = label.getAttribute("data-original-text") ?? "";
      const copiedText = window.t
        ? window.t("label_copied", "Copied!")
        : "Copied!";
      label.textContent = copiedText;
      label.classList.add("text-secondary");

      const existingTimer = label.getAttribute("data-timer-id");
      if (existingTimer) {
        window.clearTimeout(parseInt(existingTimer, 10));
      }

      const timer = window.setTimeout(() => {
        label.textContent = originalText;
        label.classList.remove("text-secondary");
        label.removeAttribute("data-timer-id");
        label.removeAttribute("data-original-text");
      }, 2000);
      label.setAttribute("data-timer-id", timer.toString());
    }
  };

  const fallbackCopy = (): void => {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();
    try {
      document.execCommand("copy");
      flashCopied();
    } catch (err) {
      console.error("Failed to copy command:", err);
    }
    document.body.removeChild(textarea);
  };

  if (navigator.clipboard && navigator.clipboard.writeText) {
    try {
      await navigator.clipboard.writeText(text);
      flashCopied();
    } catch {
      fallbackCopy();
    }
  } else {
    fallbackCopy();
  }
}

/**
 * Builds the gcloud workstations ssh command.
 */
export function buildSshCommand(singleLine = false): string {
  const cfg = state.config;
  const host = cfg.hostname || "<WORKSTATION_NAME>";
  const project = `--project=${cfg.projectId || "<PROJECT_ID>"}`;
  const cluster = `--cluster=${cfg.clusterName || "workstations"}`;
  const config = `--config=${
    cfg.configName ||
    (cfg.hostname && cfg.hostname !== "<WORKSTATION_NAME>"
      ? cfg.hostname
      : "<CONFIG_NAME>")
  }`;
  const region = `--region=${cfg.region || "<REGION>"}`;

  if (singleLine) {
    return `gcloud workstations ssh ${project} ${cluster} ${config} ${region} ${host}`;
  }

  return [
    "gcloud workstations ssh \\",
    `  ${project} \\`,
    `  ${cluster} \\`,
    `  ${config} \\`,
    `  ${region} \\`,
    `  ${host}`,
  ].join("\n");
}

/**
 * Builds the gcloud workstations start-tcp-tunnel command.
 */
export function buildTunnelCommand(
  port: number,
  singleLine = false,
  localPort?: number,
): string {
  const cfg = state.config;
  const host = cfg.hostname || "<WORKSTATION_NAME>";
  const project = `--project=${cfg.projectId || "<PROJECT_ID>"}`;
  const cluster = `--cluster=${cfg.clusterName || "workstations"}`;
  const config = `--config=${
    cfg.configName ||
    (cfg.hostname && cfg.hostname !== "<WORKSTATION_NAME>"
      ? cfg.hostname
      : "<CONFIG_NAME>")
  }`;
  const region = `--region=${cfg.region || "<REGION>"}`;
  const localFlag = localPort ? `--local-host-port=localhost:${localPort}` : "";

  if (singleLine) {
    const parts = [
      "gcloud workstations start-tcp-tunnel",
      project,
      cluster,
      config,
      region,
      host,
      port.toString(),
    ];
    if (localFlag) parts.push(localFlag);
    return parts.join(" ");
  }

  const parts = [
    "gcloud workstations start-tcp-tunnel \\",
    `  ${project} \\`,
    `  ${cluster} \\`,
    `  ${config} \\`,
    `  ${region} \\`,
  ];
  if (localFlag) {
    parts.push(`  ${host} ${port} \\`);
    parts.push(`  ${localFlag}`);
  } else {
    parts.push(`  ${host} ${port}`);
  }
  return parts.join("\n");
}

/**
 * Renders the centralized SSH/Gateway ready card inside the preflight dashboard.
 */
export function renderSshReadyCard(): void {
  const existing = document.getElementById("cws-ssh-ready-card");
  if (existing) return;

  const container =
    document.getElementById("ssh-card-container") ||
    document.getElementById("btn-manual-connect-msg")?.parentElement;
  if (!container) return;

  const manualMsgBtn = document.getElementById("btn-manual-connect-msg");
  if (manualMsgBtn) {
    manualMsgBtn.classList.add("hidden");
  }

  const cfg = state.config;
  const hasGateway = Boolean(cfg.hasJetbrainsGateway);
  const hostPort = cfg.hostSshPort ? parseInt(cfg.hostSshPort, 10) : null;
  const supportsCodeOss = cfg.connectionTypes.includes("HTTP");

  const titleText = hasGateway
    ? window.t?.("title_gateway_ready", "JetBrains Gateway / SSH Ready") ??
      "JetBrains Gateway / SSH Ready"
    : window.t?.("title_ssh_ready", "SSH Endpoint Ready") ??
      "SSH Endpoint Ready";

  const descText = hasGateway
    ? window.t?.(
        "desc_gateway_instructions",
        "Connect from your desktop via JetBrains Gateway (Cloud Workstations plugin), or run in your terminal:",
      ) ??
      "Connect from your desktop via JetBrains Gateway (Cloud Workstations plugin), or run in your terminal:"
    : window.t?.(
        "desc_ssh_instructions",
        "Connect to the workstation via Google Cloud SDK in your terminal:",
      ) ?? "Connect to the workstation via Google Cloud SDK in your terminal:";

  const copySshLabel = window.t?.("btn_copy_ssh", "Copy SSH") ?? "Copy SSH";
  const copyTunnelLabel =
    window.t?.("btn_copy_tunnel", "Copy Tunnel") ?? "Copy Tunnel";

  const sshMulti = buildSshCommand(false);
  const sshSingle = buildSshCommand(true);

  const projectLabel = window.t?.("label_project", "Project") ?? "Project";
  const regionLabel = window.t?.("label_region", "Region") ?? "Region";

  const paramsBarHtml = `
    <div id="cws-card-params-bar" class="mb-3 p-2.5 rounded-lg bg-black/40 border border-neutral-800 flex flex-wrap items-center gap-3">
      <div class="flex items-center gap-1.5 flex-1 min-w-[140px]">
        <label for="input-card-project" class="text-[10px] uppercase text-neutral-400 font-bold tracking-wider">${projectLabel}:</label>
        <input id="input-card-project" type="text" value="${
          cfg.projectId || ""
        }" placeholder="Enter GCP Project ID" class="bg-black/50 border border-neutral-700 focus:border-secondary rounded px-2 py-0.5 text-white text-[11px] font-mono w-full outline-none">
      </div>
      <div class="flex items-center gap-1.5 flex-1 min-w-[130px]">
        <label for="input-card-region" class="text-[10px] uppercase text-neutral-400 font-bold tracking-wider">${regionLabel}:</label>
        <input id="input-card-region" type="text" value="${
          cfg.region || ""
        }" placeholder="Enter GCP Region" class="bg-black/50 border border-neutral-700 focus:border-secondary rounded px-2 py-0.5 text-white text-[11px] font-mono w-full outline-none">
      </div>
    </div>
  `;

  const card = document.createElement("div");
  card.id = "cws-ssh-ready-card";
  card.className =
    "mt-4 p-5 rounded-xl border border-neutral-700 bg-neutral-900/95 text-left text-xs font-mono select-text max-w-xl mx-auto shadow-2xl backdrop-blur-md";

  let html = `
    <div class="flex items-center justify-between pb-3 mb-3 border-b border-neutral-800">
      <span class="flex items-center gap-2 text-secondary font-bold tracking-wider text-xs uppercase">
        <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
        ${titleText}
      </span>
      <div class="flex items-center gap-2">
        <button id="btn-copy-ssh" type="button" class="px-3 py-1 bg-white/10 hover:bg-white/20 active:bg-white/30 rounded text-[11px] text-white transition-all flex items-center gap-1 cursor-pointer">
          <span class="material-symbols-outlined text-sm">content_copy</span>
          <span id="copy-ssh-text">${copySshLabel}</span>
        </button>
      </div>
    </div>
    <p class="text-neutral-300 font-sans text-xs mb-3 leading-relaxed">
      ${descText}
    </p>
    ${paramsBarHtml}
    <div id="cws-ssh-code-block" class="p-3 rounded-lg bg-black/70 border border-neutral-800 font-mono text-[11px] text-neutral-200 overflow-x-auto select-all leading-relaxed whitespace-pre">${buildSshCommand(
      false,
    )}</div>
  `;

  let hostTunnelSingle = "";
  if (hostPort) {
    const hostTunnelMulti = buildTunnelCommand(hostPort, false, hostPort);
    hostTunnelSingle = buildTunnelCommand(hostPort, true, hostPort);
    const hostLabel =
      window.t?.("label_host_ssh", `Host VM Shell (Port ${hostPort})`) ??
      `Host VM Shell (Port ${hostPort})`;
    const hostDesc =
      window.t?.(
        "desc_host_ssh_instructions",
        `Connect to the host VM shell using a TCP tunnel on port ${hostPort}:`,
      ) ??
      `Connect to the host VM shell using a TCP tunnel on port ${hostPort}:`;

    html += `
      <div class="mt-4 pt-3 border-t border-neutral-800">
        <div class="flex items-center justify-between mb-2">
          <span class="text-neutral-400 font-bold tracking-wider text-[11px] uppercase">${hostLabel}</span>
          <button id="btn-copy-host-tunnel" type="button" class="px-2.5 py-0.5 bg-white/10 hover:bg-white/20 active:bg-white/30 rounded text-[10px] text-white transition-all flex items-center gap-1 cursor-pointer">
            <span class="material-symbols-outlined text-xs">content_copy</span>
            <span id="copy-host-tunnel-text">${copyTunnelLabel}</span>
          </button>
        </div>
        <p class="text-neutral-400 font-sans text-[11px] mb-2">${hostDesc}</p>
        <div id="cws-host-tunnel-code-block" class="p-2.5 rounded bg-black/60 border border-neutral-800 font-mono text-[10px] text-neutral-300 overflow-x-auto select-all whitespace-pre">${hostTunnelMulti}</div>
      </div>
    `;
  }

  if (supportsCodeOss) {
    const openCodeOssLabel =
      window.t?.("btn_open_codeoss", "Open Code-OSS") ?? "Open Code-OSS";
    html += `
      <div class="mt-3 pt-2 text-right">
        <a href="?protocol=HTTP" class="text-[11px] text-secondary hover:underline inline-flex items-center gap-1">
          <span class="material-symbols-outlined text-xs">open_in_browser</span>
          <span>${openCodeOssLabel}</span>
        </a>
      </div>
    `;
  }

  card.innerHTML = html;
  container.innerHTML = "";
  container.appendChild(card);

  const syncInputsAndBlocks = () => {
    const pInput = document.getElementById(
      "input-card-project",
    ) as HTMLInputElement | null;
    const rInput = document.getElementById(
      "input-card-region",
    ) as HTMLInputElement | null;
    if (pInput) {
      const val = pInput.value.trim();
      cfg.projectId = val;
      if (val) {
        try {
          localStorage.setItem("cws_project_id", val);
        } catch {}
      }
    }
    if (rInput) {
      const val = rInput.value.trim();
      cfg.region = val;
      if (val) {
        try {
          localStorage.setItem("cws_region", val);
        } catch {}
      }
    }
    const sshBlock = document.getElementById("cws-ssh-code-block");
    if (sshBlock) {
      sshBlock.textContent = buildSshCommand(false);
    }
    const hostBlock = document.getElementById("cws-host-tunnel-code-block");
    if (hostBlock && hostPort) {
      hostBlock.textContent = buildTunnelCommand(hostPort, false, hostPort);
    }
  };

  document
    .getElementById("input-card-project")
    ?.addEventListener("input", syncInputsAndBlocks);
  document
    .getElementById("input-card-region")
    ?.addEventListener("input", syncInputsAndBlocks);

  const copySshBtn = document.getElementById("btn-copy-ssh");
  if (copySshBtn) {
    copySshBtn.addEventListener("click", async (e) => {
      e.stopPropagation();
      await ensureProjectAndRegion();
      await copyToClipboard(buildSshCommand(true), "copy-ssh-text");
    });
  }

  if (hostPort) {
    const copyHostBtn = document.getElementById("btn-copy-host-tunnel");
    if (copyHostBtn) {
      copyHostBtn.addEventListener("click", async (e) => {
        e.stopPropagation();
        await ensureProjectAndRegion();
        await copyToClipboard(
          buildTunnelCommand(hostPort, true, hostPort),
          "copy-host-tunnel-text",
        );
      });
    }
  }
}

/**
 * Ensures projectId and region are defined before copying commands.
 * Reads from inputs if available, prompts user if empty, and updates state/storage/DOM.
 */
export async function ensureProjectAndRegion(): Promise<void> {
  const cfg = state.config;
  const pInput = document.getElementById(
    "input-card-project",
  ) as HTMLInputElement | null;
  const rInput = document.getElementById(
    "input-card-region",
  ) as HTMLInputElement | null;

  if (pInput && pInput.value.trim()) {
    cfg.projectId = pInput.value.trim();
    try {
      localStorage.setItem("cws_project_id", cfg.projectId);
    } catch {}
  } else if (!cfg.projectId) {
    let stored: string | null = null;
    try {
      stored = localStorage.getItem("cws_project_id");
    } catch {}
    const prompted = window.prompt(
      window.t?.("prompt_project_id", "Enter your Google Cloud Project ID:") ??
        "Enter your Google Cloud Project ID:",
      stored || "",
    );
    if (prompted && prompted.trim()) {
      cfg.projectId = prompted.trim();
      try {
        localStorage.setItem("cws_project_id", cfg.projectId);
      } catch {}
      if (pInput) pInput.value = cfg.projectId;
    }
  }

  if (rInput && rInput.value.trim()) {
    cfg.region = rInput.value.trim();
    try {
      localStorage.setItem("cws_region", cfg.region);
    } catch {}
  } else if (!cfg.region) {
    let stored: string | null = null;
    try {
      stored = localStorage.getItem("cws_region");
    } catch {}
    const prompted = window.prompt(
      window.t?.("prompt_region", "Enter your Workstation Region:") ??
        "Enter your Workstation Region:",
      stored || "",
    );
    if (prompted && prompted.trim()) {
      cfg.region = prompted.trim();
      try {
        localStorage.setItem("cws_region", cfg.region);
      } catch {}
      if (rInput) rInput.value = cfg.region;
    }
  }

  const sshBlock = document.getElementById("cws-ssh-code-block");
  if (sshBlock) sshBlock.textContent = buildSshCommand(false);
  const hostBlock = document.getElementById("cws-host-tunnel-code-block");
  if (hostBlock && cfg.hostSshPort) {
    const hp = parseInt(cfg.hostSshPort, 10);
    hostBlock.textContent = buildTunnelCommand(hp, false, hp);
  }
}

/**
 * Copies the primary SSH command to the clipboard (used when clicking manual connect or rocket trigger).
 */
export async function copyPrimarySshCommand(): Promise<void> {
  renderSshReadyCard();
  await ensureProjectAndRegion();
  await copyToClipboard(buildSshCommand(true), "copy-ssh-text");
}
