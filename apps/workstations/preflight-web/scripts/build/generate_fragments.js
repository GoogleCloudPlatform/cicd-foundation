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

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

import { marked } from "marked";

async function run() {
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);

  marked.setOptions({
    breaks: true,
    gfm: true,
  });

  const renderer = {
    heading(token) {
      const text = this.parser.parseInline(token.tokens);
      const level = token.depth;
      // We handle the main title (H1) externally in the modal header, so we skip it here.
      if (level === 1) {
        return "";
      }
      return `<h${level} class="text-xl font-bold text-white mt-8 mb-4 uppercase tracking-wider">${text}</h${level}>\n`;
    },
    list(token) {
      const body = token.items
        .map((item) => {
          const itemText = this.parser.parseInline(item.tokens);
          return `  <li class="ps-2">${itemText}</li>\n`;
        })
        .join("");
      const type = token.ordered ? "ol" : "ul";
      const cls = token.ordered ? "list-decimal" : "list-disc";
      return `<${type} class="${cls} ps-6 space-y-2 mb-6 text-on-surface-variant">\n${body}</${type}>\n`;
    },
    paragraph(token) {
      const text = this.parser.parseInline(token.tokens);
      if (text.startsWith("<!--")) return "";
      return `<p class="text-sm text-on-surface-variant leading-relaxed mb-4">${text}</p>\n`;
    },
    strong(token) {
      return `<strong class="text-white font-bold">${this.parser.parseInline(
        token.tokens,
      )}</strong>`;
    },
  };

  marked.use({ renderer });

  const sourcePath = path.resolve(
    __dirname,
    "../../../preflight/docs/privacy_notice.md",
  );
  const outputPath = path.resolve(process.cwd(), "public/privacy_notice.html");

  try {
    console.log(`Reading source Markdown: ${sourcePath}`);
    let md = fs.readFileSync(sourcePath, "utf8");

    // Remove the title (# Title) and any preceding/succeeding whitespace/newlines
    // We target the first H1 specifically.
    md = md.replace(/^#\s+.*(?:\r?\n)*/m, "");

    // Strip comments
    md = md.replace(/<!--[\s\S]*?-->/g, "");

    // Trim leading newlines that might remain
    md = md.trimStart();

    const html = await marked.parse(md);
    fs.writeFileSync(outputPath, html);
    console.log(
      `Successfully generated professional HTML fragment: ${outputPath}`,
    );
  } catch (err) {
    console.error("Error generating document fragments:", err);
    process.exit(1);
  }
}

run();
