# Implementation Plan: github_release_pipeline_20260312

## Phase 1: Pipeline Infrastructure [checkpoint: c0d90be]
- [x] Task: Create the GitHub Actions workflow file (`.github/workflows/release.yml`).
- [x] Task: Implement the trigger logic for `v*` tags.
- [x] Task: Configure the job matrix for Linux and macOS environments.
- [x] Task: Conductor - User Manual Verification 'Pipeline Infrastructure' (Protocol in workflow.md)

## Phase 2: Linux Build & Package [checkpoint: 325a2de]
- [x] Task: Implement Rust backend build step for Linux.
- [x] Task: Implement Flutter frontend build step for Linux.
- [x] Task: Implement packaging logic (e.g., tar.gz) for Linux assets.
- [x] Task: Conductor - User Manual Verification 'Linux Build & Package' (Protocol in workflow.md)

## Phase 3: macOS Build & Package [checkpoint: 89407bc]
- [x] Task: Implement Rust backend build step for macOS (Universal Binary).
- [x] Task: Implement Flutter frontend build step for macOS.
- [x] Task: Implement packaging logic (e.g., zip) for macOS assets.
- [x] Task: Conductor - User Manual Verification 'macOS Build & Package' (Protocol in workflow.md)

## Phase 4: Release & Documentation
- [x] Task: Implement the GitHub Release creation step with auto-generated notes.
- [x] Task: Implement the asset upload step for built Linux and macOS packages.
- [x] Task: Add the build status badge to the root `README.md`.
- [x] Task: Update README.md 'Getting Started' section with download instructions.
- [ ] Task: Conductor - User Manual Verification 'Release & Documentation' (Protocol in workflow.md)

## Phase 5: Validation
- [ ] Task: Perform a test release by pushing a dummy version tag.
- [ ] Task: Verify the release notes and attached assets on the GitHub Release page.
- [ ] Task: Verify the build status badge in `README.md`.
- [ ] Task: Conductor - User Manual Verification 'Validation' (Protocol in workflow.md)
