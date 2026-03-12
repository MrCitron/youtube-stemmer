# Specification: smart_metronome_system_20260310

## Background
Musicians need a metronome that stays in sync with the song and a count-in feature to prepare for playback.

## Requirements
- **Tempo Analysis:** Rust backend should analyze the first 10 seconds of the `original_audio.wav` to estimate the BPM.
- **Metronome Service:** A Dart service to play click sounds at a specific BPM.
- **Count-in:** Option to play 4 clicks before starting the actual audio players.
- **UI:** Add BPM display and toggle for Metronome/Count-in in the `StemPlayer`.

## Success Criteria
- Mean tempo is correctly estimated for most standard rhythmic songs.
- Metronome clicks are audible and synchronized.
- Count-in works reliably before playback starts.
