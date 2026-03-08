# Tech Stack: YouTube Stemmer

## Frontend
- **Framework:** Flutter (Dart)
- **Role:** Providing a portable, high-performance native user interface for both Desktop and Mobile platforms.

## Backend / Audio Engine
- **Framework:** Go (Golang)
- **Role:** Core logic for audio retrieval and AI inference, compiled as a shared library (.so, .dylib, .dll) for direct integration.
- **Audio Retrieval:** `github.com/kkdai/youtube/v2` (Pure Go implementation)
- **Mixing & Archiving:** `mixing` and `archiving` Go packages using `github.com/go-audio/wav` and `archive/zip`.

## Local Storage
- **Solution:** SharedPreferences / Hive (Flutter)
- **Role:** Storing user preferences, application settings, and lightweight track metadata for quick access within the Flutter UI.

## Audio & AI Libraries
- **Source Separation:** HTDemucs (Facebook Research / Meta Demucs)
- **Role:** The core engine for splitting audio tracks into high-quality stems.
- **Inference Runtime:** ONNX Runtime via `github.com/yalue/onnxruntime_go`.
- **Audio Processing Utilities:** FFmpeg (likely required by Demucs and for audio format conversions).
- **Audio I/O (Go):** `github.com/go-audio/wav` for reading/writing WAV files.
- **Networking (Frontend):** `dio` for robust file downloading of AI models.
- **Audio Playback (Frontend):** `just_audio` with `just_audio_media_kit` (for Linux support).

## Integration Strategy
- **Flutter-Go FFI Bridge:** The Flutter frontend communicates directly with the Go shared library using `dart:ffi`. Blocking calls are offloaded to background Isolates to ensure UI responsiveness.
- **Portable Packaging:** Automated scripts bundle the Flutter binary with Go/ONNX shared libraries, using relative path resolution for true "extract-and-run" portability.
- **File Selection:** `file_selector` package for native file save dialogs.
