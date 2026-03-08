# Track Specification: local_stem_import_20260308

## Description
This track allows users to bypass the YouTube download and AI stemming process if they already have stem files (e.g., from another source or a previous session) stored locally. They can select a folder, and the app will load the stems into the mixer.

## Goals
- Add a "Load Local Stems" button to the main UI.
- Implement a folder picker to select the stem directory.
- Automatically identify and load common stem files (e.g., vocals.wav, drums.wav, etc.) from the selected folder.

## Requirements
- **Folder Picker:** Integrate a native folder picker for all supported platforms.
- **Stem Detection Logic:** Search the selected folder for audio files matching expected stem names (drums, bass, other, vocals, etc.).
- **Mixer Integration:** Once files are identified, load them into the `StemPlayer` and show the mixer UI.
- **Support for Various Formats:** Handle common audio formats like WAV, MP3, and FLAC.

## Acceptance Criteria
- User can click "Load Local Stems", pick a folder, and see the stems appear in the mixer.
- The mixer functions exactly as it would for a YouTube-sourced song.
- If a folder doesn't contain valid stems, the user receives an appropriate error message.

## Out of Scope
- Syncing stems with different lengths (assume they are already aligned).
- Editing or renaming stems within the app.
