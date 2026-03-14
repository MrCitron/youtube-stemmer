# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - Cross-Platform Stability & Windows Launch

### Added
- **Windows Support**: Full support for Windows, including automated bundling of `libmpv-2.dll` and early application support directory initialization.
- **Windows Release Pipeline**: Integrated Windows builds into the automated GitHub Release process.

### Fixed
- **Windows White Screen**: Resolved a fatal crash caused by missing `libmpv` dependencies during initialization.
- **macOS Build**: Fixed Flutter embedding issues by ensuring native libraries are correctly placed during the build process.
- **UI Contrast**: Improved readability of the Log Console by fixing low-contrast buttons in Light mode.
- **URL Dropdown**: Fixed regressions on macOS and Linux related to Autocomplete synchronization and focus.
- **CI/CD Reliability**: Upgraded GitHub Actions to v6 to support Node.js 24 and fixed flaky dependency download URLs.

### Improved
- **Audio Processing**: Refactored the Rust backend to use `SampleBuffer` for reliable decoding and added sample clamping to prevent digital clipping.
- **Window Management**: Optimized default window size (900px height) to ensure the title bar remains accessible on standard laptop screens.

## [0.3.0] - Build System & Release Unification

### Improved
- **Build System**: Unified build and packaging process using a central `Makefile` and `scripts/package.py`.
- **Release Process**: Introduced a central `VERSION` file and support for snapshot builds with git-hash suffixes.
- **CI/CD Pipelines**: Optimized GitHub Actions workflows, removing redundant build steps and manual library management.
- **Cross-Platform Consistency**: Standardized artifact structure and naming across Linux, Windows, and macOS.
- **Developer Experience**: Added `release-manager` and `gh-pipeline-analyzer` agent skills.

## [0.2.0] - macOS Stability & Metronome Improvements

macOS Stability & Metronome Improvements

### Improved
- **Metronome Precision:** Significant improvements to the timing engine and audio quality. Added support for distinct downbeat sounds to improve rhythmic guidance.
- **macOS & iOS Solidification:** Finalized build configurations and library integration for a seamless experience on Apple Silicon and Intel Macs, as well as iOS.
- **UX Refinements:** Improved the History screen layout and player timeline formatting for better project management.
- **Development Workflow:** Integrated Git hooks to ensure consistent project quality.

## [0.1.0] - Initial Release

### Features
- **On-Device AI Audio Separation:** High-fidelity extraction of vocals, drums, bass, and other instruments using the HTDemucs model. **All processing is performed locally on your device**, ensuring total privacy and allowing for offline use.
- **YouTube Integration:** Direct audio retrieval from YouTube URLs for personal practice and study.
- **Studio Mixer:** Multi-track player with real-time Solo/Mute controls and volume adjustment.
- **Smart Metronome (Alpha):** Automatic BPM estimation and synchronized click track with count-in support. *(Note: Metronome audio is currently non-functional on Linux).*
- **Persistent Project History:** Save and resume your stemming projects with local SQLite storage.
- **Cross-Platform Support:** High-performance desktop application available for Linux and macOS, powered by a native Rust backend.
