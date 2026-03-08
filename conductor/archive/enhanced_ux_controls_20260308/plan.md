# Implementation Plan: enhanced_ux_controls_20260308

## Phase 1: Player Controls
- [x] Task: Add Stop, Back (-10s), and Forward (+10s) buttons to the `StemPlayer` widget.
- [x] Task: Implement the logic for these buttons in `stem_player.dart`.
- [x] Task: Update the UI layout to accommodate the new buttons.
- [x] Task: Add a progress slider for the player to allow precise seeking.

## Phase 2: Model Download Management
- [x] Task: Update `ModelDownloader` and `ModelDownloadDialog` to support cancellation.
- [x] Task: Add a confirmation step before initiating a model download.
- [x] Task: Ensure that cancelling a download properly cleans up partial files.

## Phase 3: Dual Progress Bars & ETA
- [x] Task: Enhance the progress reporting mechanism in the backend (FFI) and frontend.
- [x] Task: Implement ETA calculation logic based on processing speed.
- [x] Task: Update the UI to show two progress bars (Download & Stemming) with their respective ETAs.

## Phase 4: Validation
- [x] Task: Verify all new player controls work as expected.
- [x] Task: Test the model download confirmation and cancellation flow.
- [x] Task: Validate the accuracy and responsiveness of the dual progress bars and ETA.
- [x] Task: Conductor - User Manual Verification 'Phase 4: Integration and Final Validation' (Protocol in workflow.md)
