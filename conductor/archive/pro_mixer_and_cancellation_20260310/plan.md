# Implementation Plan: pro_mixer_and_cancellation_20260310

## Phase 1: Studio Mixer Enhancements
- [x] Task: Increase the vertical height of stem sliders in `StemPlayer.dart`.
- [x] Task: Implement "Solo" (S) state management in `StemPlayer`.
- [x] Task: Update the volume calculation logic to prioritize soloed tracks (if any are soloed, non-soloed tracks are effectively muted).
- [x] Task: Style the Solo buttons to match the mockup (active state glowing or highlighted).

## Phase 2: Cancellation Support (Frontend)
- [x] Task: Add a `CancelToken` or similar mechanism to the `_processUrl` logic.
- [x] Task: Implement a "Cancel" button in the Download and Stemming progress cards.
- [x] Task: Ensure isolates are properly killed and resources released upon cancellation.

## Phase 3: Cleanup & Robustness
- [x] Task: Implement filesystem cleanup logic to remove partial downloads or empty stem folders if a process is cancelled.
- [x] Task: Verify that the UI returns to a clean state after cancellation.

## Phase 4: Validation
- [x] Task: Test Solo/Mute combinations extensively.
- [x] Task: Verify that canceling a download actually stops the network activity.
- [x] Task: Verify that canceling stemming stops the AI inference.
