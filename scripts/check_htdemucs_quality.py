import torch
import onnxruntime as ort
import numpy as np
import os
import math
from demucs.pretrained import get_model

def check_quality(model_name, onnx_path):
    print(f"--- Quality Check: {model_name} ---")
    model = get_model(model_name)
    core_model = model
    while hasattr(core_model, 'models'):
        core_model = core_model.models[0]
    core_model.eval()
    core_model.cpu()

    # 2s dummy signal
    t = torch.linspace(0, 2, 44100 * 2)
    signal = 0.5 * torch.sin(2 * math.pi * 440 * t) + 0.3 * torch.sin(2 * math.pi * 1000 * t)
    dummy_input = signal.view(1, 1, -1).repeat(1, 2, 1)
    
    # Pad to chunk size
    chunk_size = 343980
    dummy_input = torch.nn.functional.pad(dummy_input, (0, chunk_size - dummy_input.shape[-1]))

    print("Running original PyTorch...")
    with torch.no_grad():
        out_orig = core_model(dummy_input).numpy()
    
    print("Running ONNX...")
    session = ort.InferenceSession(onnx_path)
    input_name = session.get_inputs()[0].name
    out_onnx = session.run(None, {input_name: dummy_input.numpy()})[0]
    
    # Energy Ratio (Volume check)
    orig_energy = np.sum(out_orig**2)
    onnx_energy = np.sum(out_onnx**2)
    ratio = onnx_energy / (orig_energy + 1e-9)
    db_diff = 10 * math.log10(ratio + 1e-9)
    
    print(f"Energy Ratio: {ratio:.4f} ({db_diff:.2f} dB)")
    
    if 0.95 <= ratio <= 1.05:
        print("RESULT: Quality is GOOD (matches original volume).")
    else:
        print(f"RESULT: Quality is BAD (volume mismatch: {db_diff:.2f} dB).")

if __name__ == "__main__":
    if os.path.exists("onnx_exports/htdemucs.onnx"):
        check_quality("htdemucs", "onnx_exports/htdemucs.onnx")
