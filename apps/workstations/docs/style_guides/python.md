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

# Python Style Guide

This project adheres to the [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html).

## Key Principles

### 1. Indentation

- **Convention**: Use **4 spaces** per indentation level.
- **Rationale**: Industry standard for Python (PEP 8) and ensures consistency across environments.

### 2. Naming Conventions

- **Modules/Packages**: `module_name.py` (lowercase with underscores).
- **Classes**: `ClassName` (PascalCase).
- **Functions/Methods**: `function_name()` (lowercase with underscores).
- **Variables**: `variable_name` (lowercase with underscores).
- **Constants**: `CONSTANT_NAME` (uppercase with underscores).

### 3. Strings

- **Quotes**: Use double quotes (`"`) for strings unless single quotes are needed to avoid escaping.
- **Formatting**: Prefer **f-strings** (e.g., `f"Value: {val}"`) over `.format()` or `%` operator.

### 4. Imports

- Group imports in the following order:
  1.  Standard library imports.
  2.  Related third-party imports.
  3.  Local application/library specific imports.
- Use absolute imports when possible.
- **Sorting**: Imports are automatically sorted by the **Ruff** linter in the pre-commit pipeline. Do not use `go/keep-sorted` for Python imports.

### 5. Documentation

- Use **docstrings** for all public modules, functions, and classes (PEP 257).
- Format: Use triple double quotes (`"""`).

### 6. Main Entry Point

- Always protect the execution logic with a `main` check:

  ```python
  def main():
      # logic here
      pass

  if __name__ == "__main__":
      main()
  ```

## Python in Shell Scripts (Outsourcing)

To maintain readability and testability:

1.  **Avoid complex inline Python**: If a Python snippet in a Bash script exceeds 5 lines or requires complex logic, it must be moved to a separate `.py` file in a `lib/` directory.
2.  **Explicit Execution**: Call outsourced scripts directly by ensuring they have a `#!/usr/bin/env python3` shebang and are marked as executable.
    ```bash
    "${SCRIPT_DIR}/lib/my_script.py" --args
    ```
