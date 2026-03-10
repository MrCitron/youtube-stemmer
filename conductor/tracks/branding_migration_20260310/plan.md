# Implementation Plan: branding_migration_20260310

## Phase 1: Configuration Updates
- [x] Task: Update Android `applicationId` and namespace in `frontend/android/app/build.gradle.kts`.
- [x] Task: Update Android package name in `AndroidManifest.xml` files.
- [x] Task: Update macOS `PRODUCT_BUNDLE_IDENTIFIER` in `project.pbxproj` and entitlements.
- [x] Task: Update iOS `PRODUCT_BUNDLE_IDENTIFIER` in `project.pbxproj` and info plists.
- [x] Task: Update Windows metadata in `CMakeLists.txt` or relevant resource files.

## Phase 2: Source Code & Directory Refactoring
- [x] Task: Rename Android package directories (e.g., `com/metin` -> `com/metinosman`) and update Kotlin `package` declarations.
- [x] Task: Search and replace all occurrences of `com.metin` with `com.metinosman` in the Flutter codebase.
- [x] Task: Update any hardcoded paths in the Rust backend that reference the bundle ID (e.g., for macOS Library paths).

## Phase 3: Migration & Validation
- [x] Task: Implement a logic to migrate existing data from the old directory (`com.metin...`) to the new one (`com.metinosman...`) if necessary.
- [x] Task: Verify successful builds for Linux, Windows, and macOS.
- [x] Task: Verify that History and Models are still accessible after the rename.
