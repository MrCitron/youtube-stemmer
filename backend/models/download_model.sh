#!/bin/bash
MODEL_URL="https://huggingface.co/jackjiangxinfa/demucs-onnx/resolve/main/model.onnx?download=true"
MODEL_PATH="backend/models/htdemucs.onnx"

echo "Downloading HTDemucs ONNX model..."
curl -L -o $MODEL_PATH $MODEL_URL

if [ $? -eq 0 ]; then
    echo "Model downloaded successfully to $MODEL_PATH"
else
    echo "Failed to download model."
    exit 1
fi
