# YouTube Stemmer - Rust Backend

The core logic of YouTube Stemmer is implemented in Rust. It handles audio retrieval, AI inference (using ONNX Runtime), and digital signal processing.

## 🛠️ Build Instructions

### Prerequisites

- **Rust Toolchain:** [https://rustup.rs/](https://rustup.rs/)
- **ONNX Runtime:** The `ort` crate requires the ONNX Runtime shared library (`libonnxruntime`) to be available during linking and runtime.

### Standard Build

```bash
cargo build --release
```

This will produce a shared library in `target/release/`:
- **Linux:** `libbackend.so`
- **macOS:** `libbackend.dylib`
- **Windows:** `backend.dll`

### Cross-Compilation

For platform-specific notes (like macOS Universal Binaries), see [README_MAC.md](../README_MAC.md) or the root [BUILD.md](../BUILD.md).

## 🔌 FFI Specifications

The library exports several functions for use via Dart FFI. Strings are passed as `*const c_char` and returned as `*mut c_char`. **Note:** Any string returned by the backend MUST be freed using `FreeString`.

### Core Functions

- `HelloWorld()`: Basic connection test.
- `CheckStatus() -> *mut c_char`: Returns a status message from the backend.
- `FreeString(s: *mut c_char)`: Frees a string allocated by the Rust backend.
- `CancelTasks()`: Signals the backend to abort any long-running operations (download or stemming).

### Audio & AI Functions

- `GetMetadata(url: *const c_char) -> *mut c_char`: Retrieves video title and author from a YouTube URL.
- `DownloadAudio(url: *const c_char, output_path: *const c_char, cb: ProgressCallback) -> *mut c_char`: Downloads and decodes audio to a WAV file.
- `InitStemmer(model_path: *const c_char, lib_path: *const c_char) -> *mut c_char`: Initializes the AI session.
- `SplitAudio(...) -> *mut c_char`: Performs the AI stem separation.
- `GetEstimatedBPM(path: *const c_char) -> *mut c_char`: Analyzes a WAV file and returns the estimated BPM.
- `FreeStemmer()`: Releases the AI model and session resources.

### Utilities

- `MixStems(...) -> *mut c_char`: Combines multiple WAV stems into a single output file.
- `CreateZip(...) -> *mut c_char`: Archives stems into a ZIP file.
- `CreateMp3Zip(...) -> *mut c_char`: Archives stems into a ZIP file, converting them to MP3 (Note: currently a shim/WAV in some versions).

## 🏗️ Project Structure

- `src/lib.rs`: Main FFI entry point and session management.
- `src/tempo.rs`: BPM estimation logic using autocorrelation.
- `src/click_gen.rs`: Metronome click generation logic.
- `Cargo.toml`: Dependency management (pins `ort` to `api-19`).
