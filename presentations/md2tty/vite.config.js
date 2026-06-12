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

import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  // Vite uses index.html in the root as the entry point by default.
  server: {
    open: true,
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    lib: {
      entry: resolve(__dirname, 'src/md2tty.js'),
      name: 'Md2tty',
      fileName: 'md2tty',
      formats: ['es'],
    },
    rollupOptions: {
      // Ensure marked is bundled with the library.
      // We don't mark it as external so the user gets a zero-config package.
      output: {
        assetFileNames: (assetInfo) => {
          if (assetInfo.name === 'style.css') return 'md2tty.css';
          return assetInfo.name;
        },
      },
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    include: ['src/**/*.test.js'],
  },
});
