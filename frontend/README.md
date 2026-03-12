# YouTube Stemmer - Flutter Frontend

The user interface for YouTube Stemmer is built with Flutter. It provides a modern, responsive experience for managing audio separation projects.

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK:** [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
- **Backend Library:** You must have the compiled `libbackend` (from the `backend/` directory) and `libonnxruntime` available for your platform.

### Installation

1.  **Fetch Dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Prepare Native Assets:**
    Ensure the shared libraries are in the expected search path (refer to `backend_ffi.dart` for logic).

## 🛠️ Build Commands

### Linux

```bash
flutter build linux
```
*Note: Requires `media_kit_libs_linux` dependencies (typically `libmpv-dev`).*

### macOS

```bash
flutter build macos
```
*Note: Refer to [README_MAC.md](../README_MAC.md) for critical Xcode bundling steps for `yt-dlp` and ONNX.*

### Windows

```bash
flutter build windows
```

## 📦 Key Dependencies

- **`just_audio` & `media_kit`**: Multi-platform audio playback with gapless support and Linux compatibility.
- **`sqflite`**: Persistent storage for track history and metadata.
- **`dio`**: Robust file downloading for AI model updates.
- **`window_manager`**: Custom window sizing and placement logic.
- **`file_picker`**: Native file system interactions for importing and exporting stems.

## 🏗️ Project Architecture

- `lib/main.dart`: Application entry point and main coordination logic.
- `lib/stem_player.dart`: The core mixer UI and synchronized playback engine.
- `lib/backend_ffi.dart`: The FFI bridge connecting Flutter to the Rust backend.
- `lib/history_service.dart`: SQLite-backed persistence layer.
- `lib/metronome_service.dart`: Precise timing logic for metronome clicks.
