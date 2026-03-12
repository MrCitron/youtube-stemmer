# Implementation Plan: full_backend_refactor_go_20260307

## Phase 1: Go Shared Library Foundation [checkpoint: 9573cac]
- [x] Task: Set up the Go project structure for shared library compilation (c-shared).
- [x] Task: Implement a basic FFI bridge between Go and Flutter (e.g., hello world).
- [x] Task: Research and select a Go native library for YouTube audio retrieval (e.g., `youtube-dl-go` or `yt-dlp` wrapper if necessary).
- [x] Task: Write unit tests in Go for the basic FFI bridge and initial retrieval logic.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Go Shared Library Foundation' (Protocol in workflow.md)

## Phase 2: Native Audio Retrieval (Go) [checkpoint: c772bfb]
- [x] Task: Implement the core audio retrieval logic in Go using the selected library.
- [x] Task: Integrate the Go retrieval logic into the shared library and update the Flutter FFI bridge.
- [x] Task: Write integration tests to verify audio retrieval from the Flutter side via FFI.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Native Audio Retrieval (Go)' (Protocol in workflow.md)

## Phase 3: Native AI Stemming (ONNX/Torch Go) [checkpoint: 93111e3]
- [x] Task: Research and select a Go binding for ONNX Runtime or LibTorch.
- [x] Task: Port the HTDemucs model and stemming logic to the Go environment using the selected runtime.
- [x] Task: Implement the stemming logic in Go and expose it through the shared library's FFI.
- [x] Task: Write unit and integration tests for the Go-based stemming logic.
- [x] Task: Conductor - User Manual Verification 'Phase 3: Native AI Stemming (ONNX/Torch Go)' (Protocol in workflow.md)

## Phase 4: Full Integration and Cross-Platform Validation [checkpoint: 63f7f42]
- [x] Task: Refactor the Flutter frontend to use the new Go-based FFI backend exclusively.
- [x] Task: Implement a build process for target platforms (Linux, macOS, Windows, Android, iOS).
- [x] Task: Conduct thorough testing on all platforms to ensure functionality and portability.
- [x] Task: Finalize the shared library packaging and build scripts for the final application.
- [x] Task: Conductor - User Manual Verification 'Phase 4: Full Integration and Cross-Platform Validation' (Protocol in workflow.md)

## Phase 5: Full AI Stemming Implementation [checkpoint: a05bbd7]
- [x] Task: Research and implement STFT/ISTFT and windowing logic in Go (e.g., using `go-dsp`).
- [x] Task: Prepare/Download the HTDemucs ONNX model compatible with the Go runtime.
- [x] Task: Implement the full inference pipeline in `backend/stemming/` (Pre-processing -> Inference -> Post-processing).
- [x] Task: Update the `SplitAudio` FFI function to trigger the full pipeline and save output stems.
- [x] Task: Write integration tests to verify the full stemming process.
- [x] Task: Conductor - User Manual Verification 'Phase 5: Full AI Stemming Implementation' (Protocol in workflow.md)
