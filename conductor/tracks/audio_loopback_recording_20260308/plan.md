# Implementation Plan: audio_loopback_recording_20260308

## Phase 1: Research & Prototype
- [ ] Task: Evaluate Go libraries for cross-platform loopback recording (`malgo`, `portaudio`, `beep`).
- [ ] Task: Create a standalone Go prototype to record 10 seconds of system audio to a WAV file.
- [ ] Task: Research platform-specific loopback device selection (WASAPI on Windows, Pulse/PipeWire monitor on Linux).

## Phase 2: Backend Implementation (Go)
- [ ] Task: Implement `StartRecording` and `StopRecording` FFI functions in `backend/main.go`.
- [ ] Task: Update the shared library to support real-time audio capture.
- [ ] Task: Ensure the recorded audio is saved in a standardized WAV format (44100Hz, Stereo, 16-bit).

## Phase 3: Frontend Integration (Flutter)
- [ ] Task: Update `BackendFFI` in Flutter to support the new recording functions.
- [ ] Task: Design and implement a "Record Mode" UI in `MyHomePage` (Start/Stop, recording indicator, timer).
- [ ] Task: Integrate the recorded file into the existing `_processUrl` or a new `_processRecording` flow.

## Phase 4: Validation
- [x] (Already done) Verify that the 403 Forbidden error dialog correctly suggests this fallback.
- [ ] Task: Verify recording on Linux (PulseAudio/PipeWire).
- [ ] Task: Test the full flow: Record -> Stem -> Play -> History.
- [ ] Task: Document macOS virtual audio driver requirements.
