# Implementation Plan: smart_metronome_system_20260310

## Phase 1: Tempo Analysis (Backend)
- [x] Task: Implement tempo estimation in Rust backend using the first 10 seconds of the audio.
- [x] Task: Expose the estimated BPM via a new FFI function `GetEstimatedBPM`.

## Phase 2: Metronome Service (Frontend)
- [~] Task: Create a `MetronomeService` in Dart to handle click sound playback.
- [~] Task: Implement precise timing for metronome clicks based on a target BPM.

## Phase 3: Count-in Logic
- [~] Task: Implement count-in functionality (4 beats) before playback starts.
- [~] Task: Coordinate the count-in with the `StemPlayer`'s audio initialization.

## Phase 4: UI Integration & Manual Override
- [x] Task: Update `StemPlayer` UI to display the analyzed BPM.
- [x] Task: Implement a UI control to allow users to manually set or override the BPM value.
- [x] Task: Add toggles for 'Metronome' and 'Count-in' features in the player controls.

## Phase 5: Validation
- [ ] Task: Verify BPM analysis accuracy and manual override functionality.
- [ ] Task: Ensure metronome and count-in are audible and correctly timed.
