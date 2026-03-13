---
name: release-manager
description: Manage project releases, including version bumping, changelog updates, and packaging. Use when the user wants to prepare a new release, sync versions across backend and frontend, or update the changelog.
---

# Release Manager

A senior release engineering specialist for the YouTube Stemmer project. This skill ensures consistent versioning across components and automates the release preparation process.

## Workflows

### 1. Preparing a New Release

When asked to prepare a release (e.g., "Prepare release v0.3.0"):

1.  **Check Status**: Verify the current state of `backend/Cargo.toml`, `frontend/pubspec.yaml`, and `CHANGELOG.md`.
2.  **Determine Version**: Use the version provided by the user or propose a SemVer bump.
3.  **Sync Versions**: Use `scripts/sync_version.py` from the project root.
    ```bash
    python scripts/sync_version.py <version> <YYYY-MM-DD> .
    ```
4.  **Verify Build**: Recommend running `make package-linux` to verify the build process.
5.  **Git Operations**: Propose creating a git tag and pushing it.
6.  **GitHub Release**: Draft a GitHub release description based on the `CHANGELOG.md` entry.

### 2. Updating Changelog

When asked to update the changelog with new changes:

1.  Read the `CHANGELOG.md`.
2.  Identify the `[Unreleased]` section.
3.  Append the new changes under the appropriate categories (Features, Fixed, Improved).

## Resources

-   **Sync Script**: `scripts/sync_version.py` (Project root) - Python script to automate version updates in `Cargo.toml`, `pubspec.yaml`, and `CHANGELOG.md`.
