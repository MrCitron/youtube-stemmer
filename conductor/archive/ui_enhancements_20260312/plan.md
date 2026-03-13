# Implementation Plan: ui_enhancements_20260312

## Phase 1: Smart Theming & Window Management [checkpoint: ecdc7f7]
- [x] Task: Implement "Auto" theme mode logic that follows system brightness.
- [x] Task: Set "Auto" as the default theme in application state.
- [x] Task: Implement and enforce a minimum window width (e.g., 600px) using `window_manager`.
- [x] Task: Conductor - User Manual Verification 'Smart Theming & Window Management' (Protocol in workflow.md)

## Phase 2: Database Extensions [checkpoint: f462d80]
- [x] Task: Update the SQLite schema to support a new `url_history` table (URL, Video Title, Timestamp).
- [x] Task: Implement a logic to store the 10 most recent *successful* processing URLs in the `url_history` table.
- [x] Task: Update the `history` table/model to ensure project titles are independently editable.
- [x] Task: Conductor - User Manual Verification 'Database Extensions' (Protocol in workflow.md)

## Phase 3: Smart URL Input UI [checkpoint: 95a5bfc]
- [x] Task: Redesign the URL input field to trigger a dropdown on focus/click.
- [x] Task: Implement the dropdown UI showing the last 10 successful URLs with their titles.
- [x] Task: Integrate selection logic to auto-fill the URL and start processing if desired.
- [x] Task: Conductor - User Manual Verification 'Smart URL Input UI' (Protocol in workflow.md)

## Phase 4: Mixer UI Overhaul (Mockup Alignment) [checkpoint: 646d190]
- [x] Task: Implement the 4-block vertical layout for mixer stems (Drums, Bass, Other, Vocals).
- [x] Task: Replace text Mute/Solo buttons with icons and align them vertically below sliders.
- [x] Task: Apply the specific color palette from `mockups/screen.png` to sliders, buttons, and blocks.
- [x] Task: Conductor - User Manual Verification 'Mixer UI Overhaul' (Protocol in workflow.md)

## Phase 5: Project Title Management [checkpoint: 32ff3f1]
- [x] Task: Replace the static project title label with an editable text field in the Active Project view.
- [x] Task: Implement the persistence logic to update the DB history whenever the title is changed.
- [x] Task: Conductor - User Manual Verification 'Project Title Management' (Protocol in workflow.md)

## Phase 6: Final Validation
- [x] Task: Verify theme switching across Linux and macOS.
- [x] Task: Test URL history dropdown with multiple successful and failed attempts.
- [x] Task: Verify that project title edits persist correctly across app restarts.
- [x] Task: Conductor - User Manual Verification 'Final Validation' (Protocol in workflow.md)

## Phase 7: Polish and Branding [checkpoint: 4ca0a29]
- [x] Task: Compact the process card and use the same style as other cards.
- [x] Task: Change the application icon (provide prompt if unable to generate).
- [x] Task: Update application screenshot (or request from user).
- [x] Task: Fix all compile warnings and update workflow.md to require no warnings before finishing a track.
- [x] Task: Conductor - User Manual Verification 'Polish and Branding' (Protocol in workflow.md)
