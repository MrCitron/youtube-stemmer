# Implementation Plan: app_packaging_20260307

## Phase 1: AI Model Auto-Downloader (Dart) [checkpoint: 8ab1c0e]
- [x] Task: Add `dio` or equivalent for robust file downloading.
- [x] Task: Implement `ModelDownloader` service in Flutter to fetch `htdemucs.onnx` if missing.
- [x] Task: Add a UI overlay or dialog to show download progress on first run.
- [x] Task: Write unit tests for `ModelDownloader`.
- [x] Task: Conductor - User Manual Verification 'Phase 1: AI Model Auto-Downloader' (Protocol in workflow.md)

## Phase 2: Portable Path Resolution (Go & Dart) [checkpoint: 72a3e4d]
- [x] Task: Update `BackendFFI` in Dart to resolve `libbackend` and `libonnxruntime` paths relative to the executable.
- [x] Task: Update Go backend to handle model and output paths relative to its own location or an environment variable.
- [x] Task: Write tests to verify FFI loading from relative paths.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Portable Path Resolution' (Protocol in workflow.md)

## Phase 3: Automated Packaging Scripts [checkpoint: d99c459]
- [x] Task: Create a root `scripts/package.sh` for Linux (`.tar.gz`).
- [x] Task: Create a root `scripts/package.ps1` or similar for Windows (`.zip`).
- [x] Task: Implement a 'dist' target in the root Makefile (if one exists) or `backend/Makefile`.
- [x] Task: Conductor - User Manual Verification 'Phase 3: Automated Packaging Scripts' (Protocol in workflow.md)

## Phase 4: Integration and Final Validation [checkpoint: 3cc7128]
- [x] Task: Run the automated packaging script for the current host OS.
- [x] Task: Extract the resulting archive to a clean temporary directory.
- [x] Task: Manually verify the application runs, downloads the model, and performs a full stem split.
- [x] Task: Conductor - User Manual Verification 'Phase 4: Integration and Final Validation' (Protocol in workflow.md)
