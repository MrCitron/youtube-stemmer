# Implementation Plan: rust_backend_migration_20260308

## Phase 1: Infrastructure & FFI Bridge
- [x] Task: Create `backend_rust` project structure with `cdylib` target.
- [x] Task: Implement `HelloWorld` and `CheckStatus` FFI exports.
- [x] Task: Implement `FreeString` for backward compatibility.
- [x] Task: Update GitHub Actions to build the Rust library instead of Go for all platforms.

## Phase 2: Audio Engine (Native Rust)
- [x] Task: Integrate `rustube` or `reqwest` for YouTube stream retrieval.
- [x] Task: Implement native decoding using `symphonia` (AAC/M4A -> Float32).
- [x] Task: Implement native WAV writing using `hound`.
- [x] Task: Verify `DownloadAudio` functionality without FFmpeg.

## Phase 3: AI Integration (ONNX Runtime)
- [x] Task: Integrate the `ort` crate for ONNX Runtime.
- [x] Task: Implement `InitStemmer` and `SplitAudio` logic.
- [x] Task: Re-implement chunk-based inference and planar/interleaved conversion.
- [x] Task: Ensure compatibility with ONNX Runtime v1.19.2 on macOS Big Sur.

## Phase 4: Mixing & Utilities
- [x] Task: Re-implement `MixStems` logic in Rust.
- [x] Task: Re-implement `CreateZip` and `CreateMp3Zip` using the `zip` crate and an MP3 encoder crate (MP3 is currently a shim).
- [x] Task: Finalize all FFI exports to match the Go backend signatures.

## Phase 5: Validation
- [x] Task: Verify full end-to-end flow on Linux.
- [x] Task: Verify compatibility on macOS 11.0 (Big Sur).
- [ ] Task: Verify functionality on Windows.
- [ ] Task: Document the new build process and library requirements.
