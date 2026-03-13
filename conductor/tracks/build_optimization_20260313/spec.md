# Specification: Build and Release Optimization

## Goal
Factorize and standardize the build and packaging processes across all target operating systems (Linux, Windows, macOS) to ensure consistency, reduce redundancy, and simplify maintenance.

## Scope
-   **Unified Packaging**: A single script (Python-based) to handle packaging for all platforms.
-   **Centralized Build Tool**: A comprehensive `Makefile` to orchestrate backend, frontend, and packaging steps.
-   **Workflow Refactoring**: Simplifying GitHub Action workflows (`build.yml`, `release.yml`) by delegating complexity to the local scripts.
-   **Dependency Management**: Unified way to fetch external binaries (ONNX Runtime, yt-dlp).

## Success Criteria
1.  A single `make package` command works on all supported developer environments.
2.  GitHub Actions use the `Makefile` and the unified packaging script.
3.  `scripts/package.sh` and `scripts/package.ps1` are removed or consolidated.
4.  Release artifacts are consistently structured across all platforms.
