# Track Specification: audio_loopback_recording_20260308

## Description
This track provides a fallback mechanism to capture audio for videos that cannot be directly downloaded from YouTube due to access restrictions (403 Forbidden). It will allow the user to play the video in their browser and record the system's output (loopback) in real-time within the application.

## Goals
- Research and select a cross-platform Go library for audio capture (e.g., `malgo`, `portaudio`).
- Implement a real-time recording mechanism in the Go backend.
- Expose `StartRecording` and `StopRecording` functions via FFI.
- Provide a recording UI in the Flutter frontend with a timer and level meter (if possible).
- Integrate recorded audio seamlessly into the existing stemming and history pipeline.

## Requirements
- **Loopback Recording:** Capture system audio output (what the user hears).
- **Format:** Save recordings in a standardized WAV format (44100Hz, Stereo).
- **UI:** A clear "Record" mode that allows the user to start and stop manually.
- **Metadata:** Automatically handle the resulting recording as a new song title for stemming.

## Acceptance Criteria
- User can successfully record a 30-second clip from a browser-played video.
- The recorded clip can be processed by the HTDemucs stemmer.
- The resulting stems are playable in the existing `StemPlayer`.
- Recording works on Linux (using PulseAudio/PipeWire monitor).
- (Documentation) Known platform limitations (e.g., macOS requirements) are documented.

## Out of Scope
- Internal audio routing (bypassing the speaker).
- Editing or trimming recorded clips within the app (for now).
- Recording specific applications (capturing all system audio).
