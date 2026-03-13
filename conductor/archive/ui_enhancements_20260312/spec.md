# Specification: ui_enhancements_20260312

## Overview
This track focuses on a comprehensive UI/UX overhaul of YouTube Stemmer, aligning the application's aesthetic with the provided mockup (`mockups/screen.png`). It introduces advanced features like a smart URL history dropdown, editable project titles, and a system-adaptive theme.

## Functional Requirements

### 1. Visual Overhaul (Mockup Alignment)
- **Mixer UI:** Redesign the mixer to feature 4 distinct vertical blocks for stems (Drums, Bass, Other, Vocals).
- **Mute/Solo Controls:** Replace text buttons with icons and align them vertically below each slider.
- **Color Palette:** Strictly adhere to the colors used in `mockups/screen.png` for both light and dark modes.

### 2. Smart Theming & Responsiveness
- **Adaptive Theme:** Implement an "Auto" theme mode that follows the system's light/dark setting. This should be the default state.
- **Window Management:** Compute and enforce a minimum width for the application to ensure the layout remains coherent on all platforms.

### 3. Smart URL Input
- **Search History:** Store the last 10 successfully processed YouTube URLs along with their video titles in the local SQLite database.
- **URL Dropdown:** Display a suggestion list (URL + Title) when the user interacts with the URL input area.

### 4. Project Management
- **Editable Titles:** Allow users to edit the video/project title directly in the "Active Project" view.
- **Persistence:** Any edits to the title must be automatically synchronized with the project's entry in the history database.

## Non-Functional Requirements
- **Performance:** History dropdown should load efficiently from the DB without blocking the main UI thread.

## Acceptance Criteria
- Mixer UI matches the layout and colors of the mockup.
- The app defaults to "Auto" theme and switches correctly with system settings.
- The window cannot be resized below the calculated minimum width.
- Clicking the URL area reveals a dropdown with the 10 most recent successful processing tasks.
- Editing a project title updates the label in the UI and the corresponding record in the database history.

## Out of Scope
- Implementation of additional AI models.
- Changes to the core Rust audio engine or stem separation logic.
- Cloud synchronization of history or settings.
