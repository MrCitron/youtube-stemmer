# Implementation Plan: ui_enhancements_20260312

## Phase 1: Smart Theming & Window Management
- [x] Task: Implement "Auto" theme mode logic that follows system brightness.
- [x] Task: Set "Auto" as the default theme in application state.
- [x] Task: Implement and enforce a minimum window width (e.g., 600px) using `window_manager`.
- [ ] Task: Conductor - User Manual Verification 'Smart Theming & Window Management' (Protocol in workflow.md)

## Phase 2: Database Extensions
- [ ] Task: Update the SQLite schema to support a new `url_history` table (URL, Video Title, Timestamp).
- [ ] Task: Implement a logic to store the 10 most recent *successful* processing URLs in the `url_history` table.
- [ ] Task: Update the `history` table/model to ensure project titles are independently editable.
- [ ] Task: Conductor - User Manual Verification 'Database Extensions' (Protocol in workflow.md)

## Phase 3: Smart URL Input UI
- [ ] Task: Redesign the URL input field to trigger a dropdown on focus/click.
- [ ] Task: Implement the dropdown UI showing the last 10 successful URLs with their titles.
- [ ] Task: Integrate selection logic to auto-fill the URL and start processing if desired.
- [ ] Task: Conductor - User Manual Verification 'Smart URL Input UI' (Protocol in workflow.md)

## Phase 4: Mixer UI Overhaul (Mockup Alignment)
- [ ] Task: Implement the 4-block vertical layout for mixer stems (Drums, Bass, Other, Vocals).
- [ ] Task: Replace text Mute/Solo buttons with icons and align them vertically below sliders.
- [ ] Task: Apply the specific color palette from `mockups/screen.png` to sliders, buttons, and blocks.
- [ ] Task: Conductor - User Manual Verification 'Mixer UI Overhaul' (Protocol in workflow.md)

## Phase 5: Project Title Management
- [ ] Task: Replace the static project title label with an editable text field in the Active Project view.
- [ ] Task: Implement the persistence logic to update the DB history whenever the title is changed.
- [ ] Task: Conductor - User Manual Verification 'Project Title Management' (Protocol in workflow.md)

## Phase 6: Final Validation
- [ ] Task: Verify theme switching across Linux and macOS.
- [ ] Task: Test URL history dropdown with multiple successful and failed attempts.
- [ ] Task: Verify that project title edits persist correctly across app restarts.
- [ ] Task: Conductor - User Manual Verification 'Final Validation' (Protocol in workflow.md)
