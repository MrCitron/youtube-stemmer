# Track Specification: yt_stem_mvp_20260306

## Description
This initial track focuses on building the core functionality of the YouTube Stemmer: retrieving audio from a YouTube URL and splitting it into instrument stems using a local AI model (HTDemucs).

## Goals
- Implement a Flutter-based UI for entering a YouTube URL.
- Implement a Python-based backend/engine for audio extraction and source separation.
- Integrate the two components for a seamless user experience.

## Requirements
- Support for YouTube audio retrieval via a URL.
- Local audio stemming into 4 tracks (vocals, drums, bass, other).
- Status feedback for both retrieval and processing.
