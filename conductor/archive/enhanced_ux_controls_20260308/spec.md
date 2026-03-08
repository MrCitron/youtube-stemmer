# Track Specification: enhanced_ux_controls_20260308

## Description
This track focuses on improving the user experience by adding more control over playback and background processes (downloading and stemming). It introduces standard media controls and provides better visibility into the progress of long-running tasks.

## Goals
- Add stop, back, and forward buttons to the audio player.
- Implement download confirmation and cancellation for AI models.
- Provide real-time progress feedback with dual progress bars and ETA estimation.

## Requirements
- **Media Controls:** Stop button (reset playback), Back (skip -10s), Forward (skip +10s).
- **Model Management UI:** A confirmation dialog before starting large model downloads, and a way to cancel an ongoing download.
- **Progress Tracking:** Dual progress bars in the UI. One for the current file download and one for the stemming process.
- **ETA Calculation:** Display estimated time remaining for both download and stemming operations.

## Acceptance Criteria
- User can stop, seek back, and seek forward during playback.
- User is prompted before a model download starts and can cancel it at any time.
- UI shows two distinct progress bars when both downloading and stemming are happening.
- ETA is displayed and updates accurately during these processes.

## Out of Scope
- Changing the underlying audio engine or stemming algorithm.
- Persistent history (covered in another track).
