<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# TypeScript Style Guide

This project adheres to strict typing and readability standards, heavily influenced by Google's TypeScript Readability guidelines.

## Key Principles

1. **Strict Typing**: Avoid `any`. Use precise types or `unknown` if the type is truly dynamic.
2. **No Bypassing**: NEVER use hacks like `// @ts-ignore` or casting (e.g., `as any`) unless explicitly necessary and reviewed. Use idiomatic language features like type guards (e.g., `if (typeof x === 'string')`).
3. **Readability over Cleverness**: Write code that is easy to understand. Consolidate logic into clean abstractions rather than threading state across unrelated layers.
4. **Interfaces vs. Types**: Prefer `interface` for object shapes and class contracts. Use `type` aliases for unions, intersections, and mapped types.
5. **Readonly & Immutability**:

   - **Mandate**: Use `readonly` for all interface properties and `ReadonlyArray` for collections. This prevents accidental in-place mutations.
   - **State Updates**: When updating global state or configuration, use full object replacement with the spread operator instead of direct property assignment.
   - **Example**:
     ```typescript
     // DO NOT: state.config.lang = 'fr';
     // DO:
     state.config = { ...state.config, lang: "fr" };
     ```

6. **Explicit Return Types**: Always define explicit return types for functions and methods. This prevents accidental changes to the public API contract and helps the compiler catch errors earlier.
7. **Imports**: Group and sort imports logically (e.g., standard library, third-party packages, local modules). Do not use deep relative paths (e.g., `../../../../module`); use absolute imports mapped to the project root if configured.
8. **Naming Conventions**:
   - `PascalCase` for Classes, Interfaces, Types, and Enums.
   - `camelCase` for variables, functions, and properties.
   - `CONSTANT_CASE` for global, immutable constants.
9. **JSDoc**: Use JSDoc comments for all public functions, interfaces, and complex types to ensure clear documentation. Explain _why_ the function exists, not just _what_ it does.

## Testing TypeScript

Code should be thoroughly tested using industry-standard frameworks (like **Vitest** or **Jest**).

### How to Write Tests

1. **Unit Tests**: Every file `foo.ts` (or `foo.js`) should have a corresponding `foo.spec.ts` (or `foo.spec.js`). The `.spec.*` extension is strictly preferred over `.test.*` to align with the Angular/Jasmine origins of this convention widely adopted in Google ecosystems.
2. **Isolation**: Use Mocks/Spies (e.g., `vi.fn()`, `vi.spyOn()`) to isolate the specific logic being tested. Do not test third-party library behavior.
3. **Describe/It Blocks**: Use `describe` to group related tests and `it` or `test` for individual test cases. Sentences should read naturally (e.g., `it('should return true when active', ...)`).
4. **Assertions**: Test both the "happy path" and edge cases (e.g., null inputs, thrown exceptions).
