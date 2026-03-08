#!/bin/bash

# Define log file
LOG_FILE="export_debug.log"

# Function to log both to console and file
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Clear previous log
> "$LOG_FILE"

log "--- Starting Full Export Process: $(date) ---"

# 1. Create Virtual Environment
log "Setting up Python environment..."
python3 -m venv venv_export >> "$LOG_FILE" 2>&1 || { log "FAILED to create venv"; exit 1; }
source venv_export/bin/activate

# 2. Install Dependencies
# We force Torch 2.4.1 which is stable for legacy ONNX export
log "Installing dependencies (torch 2.4.1, onnx, demucs)..."
pip install --upgrade pip >> "$LOG_FILE" 2>&1
pip install "torch==2.4.1" "torchaudio==2.4.1" onnx >> "$LOG_FILE" 2>&1 || { log "FAILED to install torch/onnx"; exit 1; }
pip install -U demucs >> "$LOG_FILE" 2>&1 || { log "FAILED to install demucs"; exit 1; }

# 3. Export 6-Stem Model
log "Exporting HTDemucs 6-stem..."
python scripts/export_to_onnx.py --model htdemucs_6s --out htdemucs_6s.onnx || { log "FAILED to export 6s model"; }

# 4. Export Fine-Tuned Model
log "Exporting HTDemucs Fine-tuned..."
python scripts/export_to_onnx.py --model htdemucs_ft --out htdemucs_ft.onnx || { log "FAILED to export ft model"; }

log "--- Export Process Finished: $(date) ---"
log "Please share the content of '$LOG_FILE' if it still fails."
