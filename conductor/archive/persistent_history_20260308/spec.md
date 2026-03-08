# Track Specification: persistent_history_20260308

## Description
This track focuses on data persistence. Currently, the app doesn't remember processed songs across sessions. This track will implement a local database to store metadata about processed videos (URL, title, stem paths, date) and provide a UI to navigate this history.

## Goals
- Implement a local database (e.g., SQLite or Hive) to store processing history.
- Add a "History" view to the frontend.
- Allow users to reload past stems into the mixer directly from history.
- Implement deletion of history items and their associated files.

## Requirements
- **Local Storage:** Use a persistent storage solution compatible with Flutter (Desktop & Mobile).
- **Metadata Storage:** Store Video ID, Title, Thumbnail URL, Model used, and paths to the generated stem files.
- **History UI:** A list view showing past processing jobs with search and sort capabilities.
- **Reloading:** Selecting a history item should instantly open the mixer with the corresponding stems.
- **Cleanup:** Deleting an item should offer the option to also delete the audio files from disk to save space.

## Acceptance Criteria
- History persists after the app is closed and reopened.
- User can see a list of all previously processed videos.
- User can click a history item to load it into the mixer without re-processing.
- User can delete a history item, and the files are removed from the `outputs/` directory.

## Out of Scope
- Cloud syncing of history.
- Exporting history to external formats (CSV/JSON).
