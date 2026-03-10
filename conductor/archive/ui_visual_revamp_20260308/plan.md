# Implementation Plan: ui_visual_revamp_20260308 (Updated from Stitch Mockup)

## Phase 1: Design & Theming
- [x] Task: Define a `ColorScheme` matching the deep purple/charcoal palette (#1A1221 background, #8B2CF5 primary).
- [x] Task: Configure `ThemeData` with Material 3, custom button styles (Filled, Tonal, Outlined), and modern typography.
- [x] Task: Implement a persistent theme toggle (Light/Dark) in the app state.

## Phase 2: Component Architecture
- [x] Task: Create a custom `VerticalStemSlider` widget for the Studio Mixer lanes.
- [x] Task: Develop a reusable `ActionCard` component for the "Process Video" and "Active Project" sections.
- [x] Task: Build the "View Logs" terminal-style overlay with copy functionality.

## Phase 3: Screen Overhaul
- [x] Task: Redesign the Home Screen to match the mockup (Header, Process Card, Progress indicators).
- [x] Task: Overhaul the `StemPlayer` to include the new Player Section (Title, large rounded controls) and the Studio Mixer.
- [x] Task: Redesign the `HistoryScreen` to use the card-based list format with project thumbnails and metadata.

## Phase 4: Validation
- [x] Task: Verify that all FFI operations (Download, Stemming, Export) work seamlessly with the new UI.
- [x] Task: Ensure responsive behavior across window resizes (especially for the vertical mixer lanes).
- [x] Task: Final polish of animations and transitions.
