# Specification: github_release_pipeline_20260312

## Overview
Implement an automated CI/CD pipeline using GitHub Actions to build, package, and release YouTube Stemmer for Linux and macOS. The pipeline will trigger when a version tag (e.g., `v1.0.0`) is pushed, creating a GitHub Release with auto-generated release notes and attached application assets. Additionally, a build status badge will be added to the root `README.md`.

## Functional Requirements
- **Trigger:** Pipeline must trigger on tags matching the `v*` pattern.
- **Cross-Platform Build:**
    - **Linux:** Build the Rust backend and Flutter frontend, package as a compressed bundle.
    - **macOS:** Build the Rust backend (Universal Binary) and Flutter frontend, package as a `.app` or compressed archive.
- **GitHub Release:**
    - Create a new release linked to the pushed tag.
    - Auto-generate release notes based on commit history.
- **Asset Attachment:** Upload the built bundles for Linux and macOS to the release page.
- **README Badge:** Add a GitHub Actions status badge to `README.md`.

## Non-Functional Requirements
- **Build Efficiency:** Reuse build caches where possible to speed up the pipeline.
- **Security:** Ensure all necessary signing keys (especially for macOS) are handled securely via GitHub Secrets.
- **Exclusion:** Windows builds are explicitly excluded from this track.

## Acceptance Criteria
- Pushing a tag like `v0.1.0` triggers the GitHub Action.
- The pipeline successfully builds both Linux and macOS versions.
- A GitHub Release is created automatically with accurate release notes.
- Downloadable assets for Linux and macOS are available on the release page.
- The `README.md` file displays a build status badge that reflects the latest run.

## Out of Scope
- Windows build and release.
- Android and iOS build and release.
- Automated code signing for macOS (unless basic ad-hoc signing is sufficient for initial testing).
- Deployment to app stores (Mac App Store, Snap Store, etc.).
