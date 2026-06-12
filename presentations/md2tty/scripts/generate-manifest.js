/*!
 * @license
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
 * @fileoverview Script to generate a manifest of slide files and copy them to the public directory.
 */

const fs = require('fs');
const path = require('path');

const SOURCE_DIR = path.resolve(process.env.SLIDES_SRC || path.join(__dirname, '../slides'));
const PUBLIC_DIR = path.join(__dirname, '../public');
const SLIDES_OUT_DIR = path.join(PUBLIC_DIR, 'slides');
const LOCALES_DIR = path.join(__dirname, '../locales');
const PUBLIC_LOCALES_DIR = path.join(PUBLIC_DIR, 'locales');

/**
 * Orchestrates the slide manifest generation.
 */
function main() {
  console.log('Generating slide manifest...');

  // Ensure directories exist.
  if (!fs.existsSync(PUBLIC_DIR)) {
    fs.mkdirSync(PUBLIC_DIR);
  }
  if (!fs.existsSync(SLIDES_OUT_DIR)) {
    fs.mkdirSync(SLIDES_OUT_DIR);
  }
  if (!fs.existsSync(PUBLIC_LOCALES_DIR)) {
    fs.mkdirSync(PUBLIC_LOCALES_DIR);
  }

  // Clean previous slides.
  const oldSlides = fs.readdirSync(SLIDES_OUT_DIR);
  for (const file of oldSlides) {
    fs.unlinkSync(path.join(SLIDES_OUT_DIR, file));
  }

  // Find and sort slides.
  const files = fs.readdirSync(SOURCE_DIR)
    .filter(file => /\.md$/.test(file))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' }));

  if (files.length === 0) {
    console.warn('Warning: No slide files (slides/*.md) found in src/');
  }

  // Copy slides to public directory.
  for (const file of files) {
    fs.copyFileSync(path.join(SOURCE_DIR, file), path.join(SLIDES_OUT_DIR, file));
  }

  // Process Locales
  if (fs.existsSync(LOCALES_DIR)) {
    const locales = fs.readdirSync(LOCALES_DIR).filter(file => /\.json$/.test(file));
    for (const file of locales) {
      const srcPath = path.join(LOCALES_DIR, file);
      // Copy JSON to public
      fs.copyFileSync(srcPath, path.join(PUBLIC_LOCALES_DIR, file));
      
      // Generate .sh equivalent
      const lang = file.replace('.json', '');
      const data = JSON.parse(fs.readFileSync(srcPath, 'utf8'));
      let shContent = `#!/bin/bash
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

declare -g -A i18n_${lang}=(\n`;
      for (const item of data) {
        const id = item.id;
        const trans = item.translation.replace(/'/g, "'\\''");
        shContent += `  ["${id}"]='${trans}'\n`;
      }
      shContent += ')\n';
      const shFilename = `${lang}.sh`;
      fs.writeFileSync(path.join(LOCALES_DIR, shFilename), shContent, 'utf8');
    }
  }

  // Write manifest.
  fs.writeFileSync(
    path.join(PUBLIC_DIR, 'slides.json'),
    JSON.stringify(files, null, 2)
  );

  console.log(`Successfully manifested ${files.length} slides.`);
}

main();
