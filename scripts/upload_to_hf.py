import os
import argparse
from huggingface_hub import HfApi, create_repo

def upload_to_hf(repo_id, token, model_dir="onnx_exports"):
    api = HfApi()
    
    print(f"Creating/Verifying repository: {repo_id}...")
    try:
        create_repo(repo_id=repo_id, token=token, repo_type="model", exist_ok=True)
    except Exception as e:
        print(f"Error creating repo: {e}")
        return

    # Files to upload
    models = ["htdemucs.onnx", "htdemucs_ft.onnx", "htdemucs_6s.onnx"]
    
    for model in models:
        file_path = os.path.join(model_dir, model)
        if os.path.exists(file_path):
            print(f"Uploading {model} to {repo_id}...")
            api.upload_file(
                path_or_fileobj=file_path,
                path_in_repo=model,
                repo_id=repo_id,
                token=token
            )
        else:
            print(f"Skipping {model}, file not found in {model_dir}")

    # Create a basic Model Card (README.md)
    # Using a raw string to avoid backslash issues, and no f-string to avoid brace issues
    readme_content = r"""---
license: cc-by-nc-4.0
language:
- en
library_name: onnx
tags:
- audio
- source-separation
- demucs
- music
- stemmer
---

# Demucs v4 (Hybrid Transformer) ONNX Models

This repository contains the official **Demucs v4** models exported to standalone ONNX format.

## Models Included:
- `htdemucs.onnx`: The standard Hybrid Transformer model.
- `htdemucs_ft.onnx`: The fine-tuned Hybrid Transformer model.
- `htdemucs_6s.onnx`: The experimental 6-source model (adds 'piano' and 'guitar').

## Export Details:
These models were exported using custom patches to bypass ONNX limitations regarding complex tensors and native multi-head attention.
- **Opset**: 14
- **Optimizations**: Constant folding applied.
- **Decomposition**: STFT and iSTFT operations are decomposed into 1D Convolutions for maximum portability.

## Licensing:
- **Code**: The Demucs source code is licensed under the **MIT License**.
- **Weights**: The weights provided here are from the original Meta AI release and are subject to the **CC-BY-NC 4.0** license (Non-Commercial, Attribution) as they were trained on the MUSDB18 dataset.

## Citation:
If you use these models, please cite the original Demucs work:
```
@article{defossez2022hybrid,
  title={Hybrid Transformer Demucs for Music Source Separation},
  author={D{\'e}fossez, Alexandre},
  journal={arXiv preprint arXiv:2211.08553},
  year={2022}
}
```
"""
    
    print("Uploading Model Card (README.md)...")
    api.upload_file(
        path_or_fileobj=readme_content.encode(),
        path_in_repo="README.md",
        repo_id=repo_id,
        token=token
    )
    
    print(f"Success! Models are now available at: https://huggingface.co/{repo_id}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload ONNX models to Hugging Face")
    parser.add_argument("--repo", type=str, required=True, help="Repository ID (e.g., 'your-username/demucs-v4-onnx')")
    parser.add_argument("--token", type=str, required=True, help="Hugging Face Write Token")
    
    args = parser.parse_args()
    upload_to_hf(args.repo, args.token)
