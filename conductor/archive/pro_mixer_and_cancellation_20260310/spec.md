# Specification: pro_mixer_and_cancellation_20260310

## Background
Improving the usability of the Studio Mixer and providing control over long-running background tasks.

## Requirements
- **Solo Logic:** Clicking 'S' on a track should mute all other tracks. Multiple tracks can be soloed.
- **Fader Height:** Increase the vertical slider height in `StemPlayer` for better precision.
- **Task Cancellation:** Add "Cancel" buttons to the progress indicators for Download and Stemming.
- **Cleanup:** Ensure temporary files are deleted if a task is cancelled.

## Success Criteria
- Solo buttons work as expected (standard DAW behavior).
- Sliders are visually longer and more precise.
- Users can stop a download or stemming process immediately.
