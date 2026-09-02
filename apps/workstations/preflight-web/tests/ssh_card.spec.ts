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

import { describe, it, expect, beforeEach, vi } from "vitest";
import { setupMockDOM } from "./helpers";
import { DEFAULT_CONFIG, state } from "../types";
import {
  buildSshCommand,
  buildTunnelCommand,
  renderSshReadyCard,
  copyToClipboard,
  copyPrimarySshCommand,
} from "../ssh_card_module";
import {
  handleHealthSuccess,
  manualConnect,
  startRedirect,
} from "../health_module";
import { windowUtils } from "../window_utils";

describe("SSH Ready Card Module", () => {
  beforeEach(() => {
    setupMockDOM();
    state.config = {
      ...DEFAULT_CONFIG,
      hostname: "test-workstation",
      projectId: "my-project",
      clusterName: "my-cluster",
      configName: "my-config",
      region: "europe-west1",
      connectionId: "SSH",
      hasGuacamole: false,
      hasJetbrainsGateway: false,
    };
  });

  describe("Command Building", () => {
    it("builds a single-line gcloud workstations ssh command with all parameters", () => {
      const cmd = buildSshCommand(true);
      expect(cmd).toBe(
        "gcloud workstations ssh --project=my-project --cluster=my-cluster --config=my-config --region=europe-west1 test-workstation",
      );
    });

    it("builds a multi-line formatted ssh command", () => {
      const cmd = buildSshCommand(false);
      expect(cmd).toContain("gcloud workstations ssh \\");
      expect(cmd).toContain("  --project=my-project \\");
      expect(cmd).toContain("  --cluster=my-cluster \\");
      expect(cmd).toContain("  --config=my-config \\");
      expect(cmd).toContain("  --region=europe-west1 \\");
      expect(cmd).toContain("  test-workstation");
    });

    it("builds start-tcp-tunnel command with specified port and localPort", () => {
      const single = buildTunnelCommand(2222, true, 2222);
      expect(single).toBe(
        "gcloud workstations start-tcp-tunnel --project=my-project --cluster=my-cluster --config=my-config --region=europe-west1 test-workstation 2222 --local-host-port=localhost:2222",
      );

      const multi = buildTunnelCommand(22, false);
      expect(multi).toContain("gcloud workstations start-tcp-tunnel \\");
      expect(multi).toContain("  test-workstation 22");
    });
  });

  describe("Card Rendering", () => {
    it("renders the standard SSH ready card into #ssh-card-container", () => {
      renderSshReadyCard();
      const card = document.getElementById("cws-ssh-ready-card");
      expect(card).not.toBeNull();
      expect(card?.textContent).toContain("SSH Endpoint Ready");
      expect(document.getElementById("btn-copy-ssh")).not.toBeNull();
      expect(
        document
          .getElementById("btn-manual-connect-msg")
          ?.classList.contains("hidden"),
      ).toBe(true);
    });

    it("renders JetBrains Gateway title and instructions when hasJetbrainsGateway is true", () => {
      state.config = {
        ...state.config,
        hasJetbrainsGateway: true,
      };
      renderSshReadyCard();
      const card = document.getElementById("cws-ssh-ready-card");
      expect(card?.textContent).toContain("JetBrains Gateway / SSH Ready");
      expect(card?.textContent).toContain("JetBrains Gateway");
    });

    it("renders host VM shell section when hostSshPort is present", () => {
      state.config = {
        ...state.config,
        hostSshPort: "2222",
      };
      renderSshReadyCard();
      const card = document.getElementById("cws-ssh-ready-card");
      expect(card?.textContent).toContain("Host VM Shell (Port 2222)");
      expect(document.getElementById("btn-copy-host-tunnel")).not.toBeNull();
    });

    it("renders Code-OSS quick switch link when HTTP is supported", () => {
      state.config = {
        ...state.config,
        connectionTypes: ["HTTP", "SSH"],
      };
      renderSshReadyCard();
      const card = document.getElementById("cws-ssh-ready-card");
      expect(card?.innerHTML).toContain('href="?protocol=HTTP"');
      expect(card?.textContent).toContain("Open Code-OSS");
    });

    it("does not duplicate the card if called repeatedly", () => {
      renderSshReadyCard();
      renderSshReadyCard();
      const cards = document.querySelectorAll("#cws-ssh-ready-card");
      expect(cards.length).toBe(1);
    });
  });

  describe("Clipboard Actions", () => {
    it("copies text using navigator.clipboard.writeText if available", async () => {
      const writeTextMock = vi.fn().mockResolvedValue(undefined);
      Object.defineProperty(navigator, "clipboard", {
        value: { writeText: writeTextMock },
        configurable: true,
        writable: true,
      });

      renderSshReadyCard();
      await copyPrimarySshCommand();
      expect(writeTextMock).toHaveBeenCalledWith(
        expect.stringContaining("gcloud workstations ssh"),
      );
    });

    it("resets label text to original after timeout and never gets stuck on Copied", async () => {
      vi.useFakeTimers();
      renderSshReadyCard();
      const label = document.getElementById("copy-ssh-text");
      expect(label?.textContent).toBe("Copy SSH");

      await copyToClipboard("test-cmd", "copy-ssh-text");
      expect(label?.textContent).toBe("Copied!");

      // Second click before 2000ms
      await copyToClipboard("test-cmd", "copy-ssh-text");
      expect(label?.textContent).toBe("Copied!");

      vi.advanceTimersByTime(2000);
      expect(label?.textContent).toBe("Copy SSH");
      vi.useRealTimers();
    });

    it("generates placeholders when project or region are not set", () => {
      state.config = {
        ...state.config,
        clusterName: "",
        configName: "",
        hostname: "",
        projectId: "",
        region: "",
      };
      const cmd = buildSshCommand(true);
      expect(cmd).toContain("--project=<PROJECT_ID>");
      expect(cmd).toContain("--region=<REGION>");
      expect(cmd).toContain("--cluster=workstations");
      expect(cmd).toContain("<WORKSTATION_NAME>");
    });
  });

  describe("Health Module Integration for SSH without Guacamole", () => {
    it("renders SSH card on handleHealthSuccess and prevents redirecting to Guacamole", () => {
      const assignSpy = vi.spyOn(windowUtils, "assign");
      state.config = {
        ...state.config,
        connectionId: "SSH",
        hasGuacamole: false,
        autoRedirect: true,
      };
      state.isHealthy = false;

      handleHealthSuccess();

      expect(document.getElementById("cws-ssh-ready-card")).not.toBeNull();
      expect(assignSpy).not.toHaveBeenCalled();
    });

    it("renders SSH card on startRedirect and does not navigate to Guacamole", () => {
      const assignSpy = vi.spyOn(windowUtils, "assign");
      state.config = {
        ...state.config,
        connectionId: "SSH",
        hasGuacamole: false,
      };

      startRedirect();

      expect(document.getElementById("cws-ssh-ready-card")).not.toBeNull();
      expect(assignSpy).not.toHaveBeenCalled();
    });

    it("copies primary SSH command on manualConnect when isHealthy", () => {
      const assignSpy = vi.spyOn(windowUtils, "assign");
      state.isHealthy = true;
      state.config = {
        ...state.config,
        connectionId: "SSH",
        hasGuacamole: false,
      };

      manualConnect();

      expect(document.getElementById("cws-ssh-ready-card")).not.toBeNull();
      expect(assignSpy).not.toHaveBeenCalled();
    });

    it("dynamically updates code block and localStorage when editing project and region inputs", () => {
      renderSshReadyCard();
      const projInput = document.getElementById(
        "input-card-project",
      ) as HTMLInputElement;
      const regInput = document.getElementById(
        "input-card-region",
      ) as HTMLInputElement;
      const codeBlock = document.getElementById("cws-ssh-code-block");

      expect(projInput).not.toBeNull();
      expect(regInput).not.toBeNull();

      projInput.value = "dynamic-proj";
      projInput.dispatchEvent(new Event("input"));

      regInput.value = "us-east1";
      regInput.dispatchEvent(new Event("input"));

      expect(state.config.projectId).toBe("dynamic-proj");
      expect(state.config.region).toBe("us-east1");
      expect(localStorage.getItem("cws_project_id")).toBe("dynamic-proj");
      expect(localStorage.getItem("cws_region")).toBe("us-east1");
      expect(codeBlock?.textContent).toContain("--project=dynamic-proj");
      expect(codeBlock?.textContent).toContain("--region=us-east1");
    });

    it("prompts user and updates config when project or region are missing during copy", async () => {
      state.config.projectId = "";
      state.config.region = "";
      localStorage.clear();

      const promptSpy = vi.spyOn(window, "prompt").mockImplementation((msg) => {
        if (String(msg).includes("Project")) return "prompted-proj";
        if (String(msg).includes("Region")) return "europe-west4";
        return "";
      });

      const writeTextMock = vi.fn().mockResolvedValue(undefined);
      Object.defineProperty(navigator, "clipboard", {
        value: { writeText: writeTextMock },
        configurable: true,
        writable: true,
      });

      renderSshReadyCard();
      await copyPrimarySshCommand();

      expect(promptSpy).toHaveBeenCalledTimes(2);
      expect(state.config.projectId).toBe("prompted-proj");
      expect(state.config.region).toBe("europe-west4");
      expect(writeTextMock).toHaveBeenCalledWith(
        expect.stringContaining("--project=prompted-proj"),
      );
      expect(writeTextMock).toHaveBeenCalledWith(
        expect.stringContaining("--region=europe-west4"),
      );
    });
  });
});
