# Track: Build and Release Optimization

## Status
- **Phase 1: Unified Packaging Script**: [x] (Added snapshot/release logic and `--output-name`)
- **Phase 2: Enhanced Makefile**: [x] (Consolidated backend logic, including macOS Universal)
- **Phase 3: Workflow Refactoring**: [x] (Removed all redundant build steps, simplified to `make build`)
- **Phase 4: Cleanup and Finalization**: [x]
- **Versioning Strategy**: [x] (Central `VERSION` file, `sync_version.py` in `scripts/`)
- **Project Refinement**: [x] (Removed redundant manual bundling from CMake/Xcode, fixed FFI naming)

## Context
This track was created to address the fragmented build and packaging processes discovered during a review of the GitHub pipelines and scripts.

## Key Files
- `scripts/package.py` (to be created)
- `Makefile`
- `.github/workflows/build.yml`
- `.github/workflows/release.yml`
