# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-03-12

### Added
- **GitHub Release Pipeline:** Automated builds for Linux and macOS.
- **Smart Metronome (Alpha):** Automatic BPM estimation and synchronized click track. *Note: Metronome audio is currently non-functional on Linux.*
- **Rust Backend:** High-performance audio engine and AI inference.
- **Studio Mixer:** Multi-track player with solo/mute controls.
- **Persistent History:** Save and load processed tracks via SQLite.
- **Documentation:** Comprehensive README, BUILD, and LICENSE files.
- **macOS Authorization:** Detailed Gatekeeper instructions in README.

### Fixed
- **macOS Build:** Resolved `sqlite3` hash mismatch by pinning version `3.1.7`.
