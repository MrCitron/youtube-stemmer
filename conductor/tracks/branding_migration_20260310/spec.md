# Specification: branding_migration_20260310

## Background
The user wants to transition the project's branding/namespace from `com.metin` to `com.metinosman` for professional consistency.

## Requirements
- Update `applicationId` in Android (`build.gradle`).
- Update `PRODUCT_BUNDLE_IDENTIFIER` in macOS and iOS (`project.pbxproj`).
- Update package names in `AndroidManifest.xml` and Kotlin files.
- Update Windows metadata.
- Update directory paths in Rust and Dart that rely on these identifiers (e.g., Application Support paths).

## Success Criteria
- The app builds and runs on all platforms with the new identifier.
- Persistent storage (History) is migrated or the path is updated correctly.
