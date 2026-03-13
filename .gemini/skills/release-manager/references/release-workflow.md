# Release Workflow

## Steps for a New Release

1.  **Preparation**: Ensure all features for the release are merged and tested.
2.  **Version Bump**: Decide on the next version based on [SemVer](https://semver.org/).
3.  **Sync Versions**: Update `backend/Cargo.toml`, `frontend/pubspec.yaml`, and `CHANGELOG.md` with the new version and a synthetic release name using `scripts/sync_version.py`.
4.  **Changelog**: Ensure all changes since the last release are documented in the `[Unreleased]` section of `CHANGELOG.md` before syncing versions.
5.  **Build Verification**: Run `make release` to ensure the release package can be built without errors.
6.  **Git Tagging**: Create a git tag for the new version (e.g., `git tag v1.0.0`).
7.  **Push**: Push the tag to the remote repository (`git push origin main --tags`).
8.  **GitHub Release**: Create a new release on GitHub using the tag, attaching the generated packages from the `dist/` directory.

## File Locations

-   **Version Source**: `VERSION` (Project root).
-   **Backend Version**: `backend/Cargo.toml` (`version` field).
-   **Frontend Version**: `frontend/pubspec.yaml` (`version` field).
-   **Changelog**: `CHANGELOG.md` (Update headers).

## Release Assets

-   **Linux**: `dist/linux/youtube_stemmer_linux_v0.3.0.tar.gz` (Example).
-   **macOS**: `dist/darwin/youtube_stemmer_macos_v0.3.0.zip` (Example).
