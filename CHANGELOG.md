# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - Initial Release

### Features
- **On-Device AI Audio Separation:** High-fidelity extraction of vocals, drums, bass, and other instruments using the HTDemucs model. **All processing is performed locally on your device**, ensuring total privacy and allowing for offline use.
- **YouTube Integration:** Direct audio retrieval from YouTube URLs for personal practice and study.
- **Studio Mixer:** Multi-track player with real-time Solo/Mute controls and volume adjustment.
- **Smart Metronome (Alpha):** Automatic BPM estimation and synchronized click track with count-in support. *(Note: Metronome audio is currently non-functional on Linux).*
- **Persistent Project History:** Save and resume your stemming projects with local SQLite storage.
- **Cross-Platform Support:** High-performance desktop application available for Linux and macOS, powered by a native Rust backend.
