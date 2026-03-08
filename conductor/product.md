# Initial Concept

An application to retrieve a music from a streaming platform (focused on youtube at the beginning but maybe extended to Deezer in the future), and split the songs into instrument to help people practice playing over the song without a specific part (for example the guitar track), or on the opposite, focus on a dedicated instrument or voice. I want to use a local model to do the split (aka stemming) of the song. For example, HTDemucs

---

# Product Definition: YouTube Stemmer

## Vision
A portable, cross-platform application designed for musicians to retrieve and split songs from streaming services (starting with YouTube) into individual instrument stems. By using local AI models (e.g., HTDemucs) and leveraging the user's existing subscriptions to streaming platforms, the app empowers hobbyists and enthusiasts to practice alongside their favorite tracks, isolate specific parts for study, or create custom backing tracks.

## Target Audience
- **Hobbyist Musicians & Enthusiasts:** People who want a flexible tool to practice playing their instrument over popular songs.
- **Self-Taught Learners:** Musicians who need to isolate specific tracks (e.g., bass or guitar) to understand and learn a part more effectively.

## Core Features
1. **Streaming Integration (Audio Retrieval):** Efficiently retrieve audio from YouTube (with planned expansion to Deezer) using the user's own subscriptions. **Note:** The purpose is not to download or distribute music, but to enable track splitting for personal study.
2. **Local Audio Stemming (AI Source Separation):** Split audio into high-quality stems (vocals, drums, bass, and other) using local AI models like HTDemucs.
3. **Multi-track Audio Player (Mixer):** A dedicated player that allows users to mute or solo specific tracks in real-time for a tailored practice session.
4. **Audio Export:** Export separated stems or custom mixes in common formats (WAV/MP3) for personal use and study in other software.
5. **Portable Distribution:** Distribution as self-contained archives for Linux, Windows, and macOS, with automatic AI model downloading to ensure a smooth first-run experience.

## Platform and Technology
- **Framework:** Flutter (for portable native application on Desktop and Mobile).
- **Processing:** Self-contained architecture using a Go-based core compiled as a shared library, integrated via FFI for maximum portability and minimal system dependencies.

## Primary Value
As a **Comprehensive Practice Tool**, the application provides musicians with the ultimate flexibility to either isolate a track for study or remove it to create a personalized backing track, all within a single, user-friendly interface.
