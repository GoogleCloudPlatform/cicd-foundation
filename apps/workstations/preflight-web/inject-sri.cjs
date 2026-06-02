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

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const distDir = path.join(__dirname, "dist");
const htmlPath = path.join(distDir, "startup.html");

if (!fs.existsSync(htmlPath)) {
  console.error("startup.html not found in dist.");
  process.exit(1);
}

let html = fs.readFileSync(htmlPath, "utf8");

// Regex to find script and link tags that reference local assets
const scriptRegex = /<script [^>]*src="([^"]+)"[^>]*><\/script>/g;
const styleRegex = /<link [^>]*href="([^"]+)"[^>]*rel="stylesheet"[^>]*>/g;

function injectIntegrity(regex, tagPrefix) {
  let match;
  while ((match = regex.exec(html)) !== null) {
    const fullTag = match[0];
    let assetPath = match[1];

    if (assetPath.startsWith("/")) {
      assetPath = assetPath.substring(1);
    }

    const absPath = path.join(distDir, assetPath);
    if (fs.existsSync(absPath) && assetPath !== "config.js") {
      const fileBuffer = fs.readFileSync(absPath);
      const hash = crypto
        .createHash("sha384")
        .update(fileBuffer)
        .digest("base64");
      const integrity = `sha384-${hash}`;

      // Insert the integrity and crossorigin attributes
      const newTag = fullTag.replace(
        `${tagPrefix}`,
        `${tagPrefix} integrity="${integrity}" crossorigin="anonymous" `,
      );
      html = html.replace(fullTag, newTag);
      console.log(`Injected SRI for ${assetPath}`);
    }
  }
}

injectIntegrity(scriptRegex, "<script ");
injectIntegrity(styleRegex, "<link ");

// Locale Hashing
const localesDir = path.join(__dirname, "public", "locales");
const localeHashes = {};

if (fs.existsSync(localesDir)) {
  const files = fs.readdirSync(localesDir);
  for (const file of files) {
    if (file.endsWith(".json")) {
      const fileBuffer = fs.readFileSync(path.join(localesDir, file));
      const hash = crypto
        .createHash("sha384")
        .update(fileBuffer)
        .digest("base64");
      localeHashes[file] = `sha384-${hash}`;
      console.log(`Generated hash for locale: ${file}`);
    }
  }
}

const hashesPath = path.join(distDir, "locale-hashes.json");

// SBOM Hashing
const sbomPath = path.join(__dirname, "public", "sbom.json");
if (fs.existsSync(sbomPath)) {
  const fileBuffer = fs.readFileSync(sbomPath);
  const hash = crypto.createHash("sha384").update(fileBuffer).digest("base64");
  localeHashes["sbom.json"] = `sha384-${hash}`;
  console.log(`Generated hash for SBOM`);
}

fs.writeFileSync(hashesPath, JSON.stringify(localeHashes, null, 2));
console.log(`Locale hashes written to ${hashesPath}`);

fs.writeFileSync(htmlPath, html);
console.log("SRI injection complete.");
