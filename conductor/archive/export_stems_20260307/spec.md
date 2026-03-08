# Track Specification: export_stems_20260307

## Overview
This track introduces the ability for users to export the separated instrument stems from the application. Users will be able to export either the full set of stems as a ZIP archive or a combined 'Mixdown' of the currently unmuted tracks.

## Functional Requirements
- **ZIP Export:** Package all four separated stems (vocals, drums, bass, other) into a single ZIP archive.
- **Mixdown Export:** Combine all unmuted stems into a single audio file, respecting the current mixer's volume and mute/solo settings.
- **Format Support:** Provide options to export in both **WAV** (lossless) and **MP3** formats.
- **Destination Selection:** Utilize the system's native file picker to allow users to choose the destination directory and filename for their exports.
- **Progress Feedback:** Display a clear progress indicator during the encoding and export process.

## Technical Considerations
- **Go Core Logic:** Implement the audio mixing, ZIP packaging, and WAV encoding logic entirely within the Go shared library using pure Go packages (e.g., `archive/zip`, `github.com/go-audio/wav`).
- **Dependency Minimization:** Avoid reliance on system-installed tools like FFmpeg. For MP3 encoding, prioritize pure Go implementations or include a portable, bundled library if necessary.
- **Non-Blocking Operation:** The export process must run in a background isolate to ensure the Flutter UI remains responsive.

## Acceptance Criteria
- [ ] User can successfully export all 4 stems as a ZIP file in both WAV and MP3 formats.
- [ ] User can successfully export a combined mix of unmuted stems as a single file in both WAV and MP3 formats.
- [ ] Exported files are saved to the user-selected location via the system file picker.
- [ ] The application remains responsive during the export process, showing a progress bar or spinner.
- [ ] Appropriate success/error messages are displayed upon completion or failure.

## Out of Scope
- Advanced mixing effects (panning, EQ, compression) in the exported mixdown.
- Direct integration with external cloud storage APIs.
