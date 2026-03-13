# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
