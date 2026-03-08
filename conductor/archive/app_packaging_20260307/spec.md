# Track Specification: app_packaging_20260307

## Overview
This track focuses on creating portable distribution packages for the YouTube Stemmer application across Linux, Windows, and macOS. The goal is to provide a simple, downloadable archive that users can extract and run with minimal manual setup.

## Functional Requirements
- **Multi-Platform Support:** Generate portable archives for Linux (`.tar.gz`), Windows (`.zip`), and macOS (`.zip` or `.dmg`).
- **Portable Directory Structure:** Define a standardized structure for the package (e.g., `bin/`, `lib/`, `data/`) to ensure all components are correctly located.
- **Dependency Management (Native):** Bundle necessary native libraries (like `libbackend` and `libonnxruntime`) within the package.
- **AI Model Handling:** Implement a "Download on Run" strategy. If the ~300MB HTDemucs model is missing, the application should prompt the user or automatically download it to a local data directory.
- **Automated Packaging Script:** Create a master shell script (e.g., `package.sh` or `Makefile` target) that builds both the Go backend and Flutter frontend, organizes the files, and creates the final archives.

## Technical Considerations
- **Flutter Build:** Use `flutter build linux`, `flutter build windows`, and `flutter build macos`.
- **Go Build:** Leverage the existing `backend/Makefile` for cross-compilation.
- **Path Resolution:** Update the application logic to resolve paths relative to the executable (using `Platform.resolvedExecutable` or similar) to ensure it works correctly when moved.
- **Download Logic:** Use a Dart-based downloader (e.g., `dio` or `http`) to fetch the model from Hugging Face if not present in the expected location.

## Acceptance Criteria
- [ ] A single command can generate distribution-ready archives for the target platforms.
- [ ] The Linux package can be extracted and run on a clean system (assuming basic dependencies like GTK/GLib are present).
- [ ] The application successfully detects a missing AI model and initiates a download.
- [ ] The application correctly loads bundled native libraries via FFI using relative paths.

## Out of Scope
- Creating system-level installers (e.g., `.deb`, `.msi`, `.pkg`) in this initial phase.
- Code signing and notarization (though these are recommended for production macOS/Windows apps).
