# Track Specification: full_backend_refactor_go_20260307

## Description
This track focuses on a complete refactoring of the backend from Python (FastAPI) to Go (Golang). The primary goal is to achieve maximum portability and a self-contained application architecture. The Go backend will be compiled as a shared library (FFI) to be integrated directly with the Flutter frontend, supporting Linux, macOS, Windows, Android, and iOS.

## Goals
- Rewrite the core audio processing and retrieval logic in Go.
- Integrate a native Go library for YouTube audio retrieval.
- Implement source separation (HTDemucs) using native runtimes (e.g., ONNX Runtime or LibTorch via Go bindings).
- Package the backend as a shared library (.so, .dylib, .dll) for Flutter FFI integration.
- Ensure cross-platform support across Desktop (Linux, macOS, Windows) and Mobile (Android, iOS).

## Requirements
- **Go-based Backend:** Core logic in Go, compiled to shared libraries for each target platform.
- **Native Audio Retrieval:** Use a Go library for retrieving audio from YouTube URLs.
- **Native AI Stemming:** Utilize ONNX Runtime or LibTorch Go bindings for HTDemucs source separation.
- **Flutter FFI Integration:** Implement a robust bridge between the Flutter frontend and the Go shared library.
- **Single-Binary Portability:** The final application should feel like a single, self-contained unit with minimal system dependencies.

## Acceptance Criteria
- Successful compilation of the Go backend for all target platforms (Linux, macOS, Windows, Android, iOS).
- Flutter frontend can successfully call the Go backend via FFI for audio retrieval and stemming.
- Audio retrieval and stemming functions correctly on all supported platforms.
- The application remains functional and stable after the refactor.

## Out of Scope
- Introducing new user-facing features (beyond the core retrieval and stemming).
- Rewriting the Flutter UI (unless necessary for FFI integration).
- Supporting additional streaming services (e.g., Deezer) in this phase.
