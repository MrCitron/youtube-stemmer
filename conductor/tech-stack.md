# Tech Stack: YouTube Stemmer

## Frontend
- **Framework:** Flutter (Dart)
- **Role:** Providing a portable, high-performance native user interface for both Desktop and Mobile platforms.

## Backend / Audio Engine
- **Framework:** Rust
- **Role:** Core logic for audio retrieval (via yt-dlp), AI inference, and DSP, compiled as a shared library (.so, .dylib, .dll) for direct integration.
- **Audio Decoding:** `symphonia` (Native Rust)
- **AI Inference:** `ort` (ONNX Runtime Rust bindings)
- **Tempo Analysis:** Native Rust autocorrelation-based estimation.
- **Mixing & Archiving:** Native Rust using `hound` (WAV) and `zip` crates.

## Local Storage
- **Solution:** `sqflite` (SQLite for Flutter)
- **Role:** Persistent storage for track history, analyzed BPMs, and application state.

## CI/CD Pipeline
- **Solution:** GitHub Actions
- **Role:** Automated build and release pipeline for Linux and macOS, triggered on version tags (`v*`). Handles cross-platform compilation, packaging, and asset uploads.
- **Release Automation:** Automated GitHub Release creation with notes extracted from `CHANGELOG.md`.

## Audio & AI Libraries
- **Source Separation:** HTDemucs (Facebook Research / Meta Demucs)
- **Role:** The core engine for splitting audio tracks into high-quality stems.
- **Inference Runtime:** ONNX Runtime (CPU/CoreML/DirectML).
- **Networking (Frontend):** `dio` for robust file downloading of AI models.
- **Audio Playback (Frontend):** `just_audio` with `just_audio_media_kit` (for Linux support).

## Integration Strategy
- **Flutter-Rust FFI Bridge:** The Flutter frontend communicates directly with the Rust shared library using `dart:ffi`. Blocking calls are offloaded to background Isolates to ensure UI responsiveness.
- **Portable Packaging:** Automated scripts bundle the Flutter binary with Rust/ONNX shared libraries, using relative path resolution for true "extract-and-run" portability.
- **File Selection:** `file_selector` package for native file save dialogs.
