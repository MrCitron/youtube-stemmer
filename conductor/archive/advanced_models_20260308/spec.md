# Track Specification: advanced_models_20260308

## Description
This track expands the application's capabilities by allowing users to choose between different AI models for source separation. This includes standard 4-track models, 6-track models (e.g., adding piano and guitar), and potentially fine-tuned models for specific genres.

## Goals
- Implement a model selection UI in the frontend.
- Update the backend to support different ONNX model architectures and output track counts.
- Add support for downloading and managing multiple model files.

## Requirements
- **Model Selection UI:** A dropdown or toggle to select between available models (e.g., HTDemucs 4-track, HTDemucs 6-track).
- **Dynamic Track Handling:** The UI (mixer/player) must dynamically adapt to the number of tracks returned by the selected model.
- **Backend Model Loading:** The Go backend must be able to load and run different ONNX models based on user selection.
- **Model Metadata:** A way to define model properties (name, tracks, size, URL) in a configuration file or embedded in the app.

## Acceptance Criteria
- User can select a 6-track model and see 6 sliders in the mixer after processing.
- User can switch back to a 4-track model and see 4 sliders.
- The app correctly downloads and stores different model files.
- The backend handles different model input/output shapes correctly.

## Out of Scope
- Training new models.
- Real-time model switching during playback (requires re-processing).
