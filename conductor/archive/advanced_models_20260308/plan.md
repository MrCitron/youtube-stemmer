# Implementation Plan: advanced_models_20260308

## Phase 1: Model Definition & Backend Prep
- [x] Task: Define a schema for model metadata (e.g., JSON) to describe available models.
- [x] Task: Update the Go backend to accept a model path/ID as an argument for stemming.
- [x] Task: Modify `stemming.go` to handle dynamic output track counts based on the loaded model.

## Phase 2: Frontend Model Selection
- [x] Task: Implement the model selection UI in the Flutter frontend (HIDDEN for now).
- [x] Task: Update `ModelDownloader` to handle multiple models and their respective paths.
- [x] Task: Migrate model hosting to Hugging Face (`MrCitron/demucs-v4-onnx`) for reliable access.
- [x] Task: Simplify UI by using 4-track default and hiding model selection.

## Phase 3: Dynamic Mixer UI
- [x] Task: Refactor `StemPlayer` and related widgets to dynamically generate track sliders based on the model's output.
- [x] Task: Ensure the audio mixing logic handles a variable number of input streams.

## Phase 4: Validation
- [x] Task: Verify architectural integration between Frontend and Backend for dynamic stem counts.
- [x] Test with HTDemucs (4-track) and verify 4 stems (Drums, Bass, Other, Vocals).
- [x] Verify that the standard 4-track model downloads correctly from Hugging Face.
- [x] Conductor - User Manual Verification 'Phase 4: Integration and Final Validation' (Protocol in workflow.md)
