# Implementation Plan: export_stems_20260307

## Phase 1: Go Backend Logic [checkpoint: 883307a]
- [x] Task: Write Go unit tests for audio mixing (unmuted stems).
- [x] Task: Implement Go-native audio mixing logic (WAV summing with gain).
- [x] Task: Write Go unit tests for ZIP archiving.
- [x] Task: Implement Go-native ZIP archiving utility using `archive/zip`.
- [x] Task: Export mixing and ZIP functions via FFI and update `libbackend.h`.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Go Backend Logic' (Protocol in workflow.md)

## Phase 2: Flutter Integration and UI [checkpoint: b3d1ea2]
- [x] Task: Add `file_picker` dependency to `pubspec.yaml`.
- [x] Task: Update `BackendFFI` Dart wrapper with new export functions.
- [x] Task: Implement a background Isolate in Flutter to manage the export lifecycle.
- [x] Task: Create the Export UI component (buttons, format toggle, progress feedback).
- [x] Task: Integrate `file_picker` for selecting export destinations.
- [x] Task: Write widget tests for the new Export UI and integration tests for the flow.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Flutter Integration and UI' (Protocol in workflow.md)

## Phase 3: Refinement and Quality Assurance [checkpoint: ba89e40]
- [x] Task: Implement detailed progress reporting from the background Isolate to the UI.
- [x] Task: Add robust error handling for file system permissions and encoding failures.
- [x] Task: Final cross-platform validation (confirming builds for Linux and preparing for others).
- [x] Task: Conductor - User Manual Verification 'Phase 3: Refinement and Quality Assurance' (Protocol in workflow.md)

## Phase 4: MP3 Encoding Implementation [checkpoint: 4a8e602]
- [x] Task: Integrate `braheezy/shine-mp3` library into the Go backend.
- [x] Task: Implement MP3 encoding for mixed stems in Go.
- [x] Task: Implement MP3 encoding for ZIP archive (converting WAVs to MP3s inside ZIP).
- [x] Task: Update FFI bridge and Flutter UI to enable MP3 export option.
- [x] Task: Conductor - User Manual Verification 'Phase 4: MP3 Encoding Implementation' (Protocol in workflow.md)
