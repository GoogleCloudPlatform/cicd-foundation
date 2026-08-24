# Image Customization Guide

This guide details best practices and mechanisms for customizing Google Cloud Workstation images downstream. It outlines the robust build hook architecture and documents the global utility functions mapped natively into the base layer.

## 1. The Build Hook Philosophy
Traditionally, extending Docker images results in massive `Dockerfile` bloat (lengthy `bash -c` executions, chained `&&` operators, and inline permission hacking). 

To solve this, the `base` image abstracts execution away from the `Dockerfile` into rigid architectural directories: `/assets/build-hooks.d/`.

### 1.1 Positional Execution
When constructing a custom image layered on `base`, do not write arbitrary `RUN` commands. Drop your setup scripts securely into nested "tier" directories inside `assets/build-hooks.d/` (e.g. `assets/build-hooks.d/tier1/01_install_java.sh`).

Inside your `Dockerfile`, orchestrate the script execution using positional arguments targeting your hooks seamlessly:
```dockerfile
# Executes all scripts dynamically located inside build-hooks.d/tier1/
RUN /google/scripts/build/configure_workstation.sh tier1
```

### 1.2 The Power of "Tiering"
Why separate scripts into directories like `tier1` and `tier2` instead of flattening them into a single run? 

**Docker Layer Caching**. 
By separating execution into distinct `RUN` abstractions inside the `Dockerfile`, they inherently compile as separate Docker image layers natively. 
- **Tier 1 (Core)**: Huge, slow-moving setups (Java, Docker runtimes, C++ abstractions).
- **Tier 2 (Cloud)**: Moderate SDKs (Terraform, Node, Go).
- **Tier 3 (Utils)**: Rapidly iterating custom internal scripts.

If you flatten everything, editing a 3-line utility script aggressively invalidates the entire Docker layer cache, brutally forcing the host to rebuild Java and C++ from scratch (a 10-minute compile). By structuring into tiers, editing a Tier 3 script instantly re-uses the Tier 1 and Tier 2 caches, dropping build times down to seconds natively!

## 2. API Reference: `install_functions.sh`

The `base` image encapsulates an incredibly robust orchestration library securely natively inside `/google/scripts/build/install_functions.sh`.

Any custom hook dumped into `build-hooks.d` should statically source this library directly:
```bash
# shellcheck source=/dev/null
source /google/scripts/build/install_functions.sh
```

### `download_and_validate`
Safely retrieves URLs dynamically leveraging `CURL_OPTS` with generic timeout/retry backing.
**Signature**: `download_and_validate <url> <sha256> <dest>`
*Bypass*: Pass `"NOCHECK"` natively as the `sha256` parameter to instantly bypass explicit checksum validation completely when necessary.

### `install_binary_from_tarball`
A universal one-shot extraction utility. It orchestrates the HTTP grab, tarball extraction, dynamic directory creation, binary translocation, arbitrary renaming, and symlink multiplexing securely within a single execution parameter!
**Signature**: `install_binary_from_tarball <url> <sha256> <archive_name> <binary_path_inside_tar> <dest_dir> <renamed_binary> [...aliases]`

### `install_file_from_tarball`
A POSIX-strict utility designed to extract heavily nested archives explicitly targeting specific file extensions (e.g., extracting purely `*.jar`), ignoring all proprietary schema bloat cleanly. 
*Note: Designed to avoid Alpine Busybox `tar` parsing breakages.*
**Signature**: `install_file_from_tarball <url> <sha256> <dest_dir> <file_glob>`

### `install_archive` & `install_debs`
The master abstractions. Pass raw strings into it and it natively identifies protocol configurations. If the file is relative, it dynamically appends internal Google software architecture `gs://` buckets. It wraps `gsutil` for secure internal downloads alongside `.zip` and `.deb` deployment processing locally.
**Signature**: `install_archive <path> <dest>`

### `fetch_image` 
Uses `crane` to orchestrate massive registry image transfers locally, insulated natively inside robust exponential failure timing mechanisms organically.
**Signature**: `fetch_image <image_registry_id> <output.tar>`

## 3. Security Paradigms: `trap EXIT`
When configuring proprietary infrastructure proxies functionally upstream of your internal installations (e.g., exposing an auth token or unshielding apt proxies), it is highly dangerous to rely physically on `&&` short circuits inside standard execution blocks. 

If the installation block dies silently, the short circuit organically halts the execution, dangerously stranding unauthenticated credentials into intermediate image artifact layers physically natively.

To mitigate this cleanly, design local standalone script wrappers explicitly invoking standard bash `trap` safety logic natively:
```bash
# configure_tier.sh wrapper
source /google/scripts/build/install_functions.sh

unshield_proxies
# GUARANTEES proxy removal regardless of downstream execution success/failure!
trap shield_proxies EXIT 

/google/scripts/build/configure_workstation.sh "$@"
```
