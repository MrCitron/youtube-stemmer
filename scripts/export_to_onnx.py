import os
import sys
import torch
import torch.nn as nn
import onnx
import argparse
import traceback
import math
import torch.nn.functional as F

def log(message):
    print(message)
    with open("export_debug.log", "a") as f:
        f.write(message + "\n")

# Custom Symbolic for Opset 17 to bypass complex STFT issues
def patch_onnx_symbolic():
    try:
        from torch.onnx import symbolic_helper
        import torch.onnx.symbolic_opset17 as opset17
        
        _orig_stft = opset17.stft
        # Force STFT to real [..., 2] in ONNX
        def patched_stft_symbolic(g, self, n_fft, hop_length, win_length, window, normalized, onesided, return_complex=None):
            return _orig_stft(g, self, n_fft, hop_length, win_length, window, normalized, onesided, return_complex=False)
        opset17.stft = patched_stft_symbolic
        log("Patched torch.onnx.symbolic_opset17.stft")
    except Exception as e: log(f"Warning: {e}")

# Manual MHA implementation to avoid _native_multi_head_attention
def manual_mha(query, key, value, ed, nh, ipw, ipb, opw, opb, am=None):
    T, B, C = query.shape
    S = key.shape[0]; hd = C // nh; sc = float(hd)**-0.5
    qkv = F.linear(query, ipw, ipb); q, k, v = qkv.chunk(3, dim=-1)
    q = q.view(T, B, nh, hd).permute(1, 2, 0, 3).reshape(B*nh, T, hd)
    k = k.view(S, B, nh, hd).permute(1, 2, 0, 3).reshape(B*nh, S, hd)
    v = v.view(S, B, nh, hd).permute(1, 2, 0, 3).reshape(B*nh, S, hd)
    att = torch.bmm(q*sc, k.transpose(1, 2))
    if am is not None: att += am
    att = F.softmax(att, dim=-1); out = torch.bmm(att, v)
    out = out.view(B, nh, T, hd).permute(2, 0, 1, 3).reshape(T, B, C)
    return F.linear(out, opw, opb)

class DemucsWaveformWrapper(nn.Module):
    def __init__(self, model):
        super().__init__()
        self.model = model
    def forward(self, x): return self.model(x)

def patch_demucs():
    log("Patching demucs for High-Fidelity export (Native Bridge)...")
    try:
        import demucs.hdemucs, demucs.htdemucs, demucs.spec
        
        demucs.hdemucs.pad1d = lambda x, p, m="reflect", v=0: F.pad(x, p, m, v)
        demucs.htdemucs.pad1d = demucs.hdemucs.pad1d

        # 1. Native Spectrogram forced to real [..., 2] for ONNX
        def patched_spectro(x, n_fft=512, hop_length=None, pad=0):
            shape = x.shape
            x_flat = x.reshape(-1, shape[-1])
            z = torch.stft(x_flat, n_fft*(1+pad), hop_length or n_fft//4,
                        window=torch.hann_window(n_fft).to(x),
                        win_length=n_fft, normalized=True, center=True,
                        return_complex=False, pad_mode='reflect')
            return z.view(*shape[:-1], z.shape[-3], z.shape[-2], 2)
        demucs.spec.spectro = patched_spectro

        # 2. Native iSTFT with real [..., 2] bridge
        def patched_ispectro(z, hop_length=None, length=None, pad=0):
            shape = z.shape
            F, T = shape[-3], shape[-2]
            n_fft = 2*F - 2
            z_flat = z.reshape(-1, F, T, 2)
            # Bridge to complex for native istft logic during trace
            z_complex = torch.view_as_complex(z_flat.contiguous())
            return torch.istft(z_complex, n_fft, hop_length,
                            window=torch.hann_window(n_fft//(1+pad)).to(z_complex.real),
                            win_length=n_fft//(1+pad), normalized=True,
                            length=length, center=True, return_complex=False).view(*shape[:-3], -1)
        demucs.spec.ispectro = patched_ispectro

        demucs.htdemucs.HTDemucs._magnitude = lambda self, z: (
            z.permute(0, 1, 4, 2, 3).reshape(z.shape[0], z.shape[1] * 2, z.shape[2], z.shape[3])
        )
        demucs.htdemucs.HTDemucs._mask = lambda self, z, m: (
            m.view(m.shape[0], m.shape[1], -1, 2, m.shape[3], m.shape[4]).permute(0, 1, 2, 4, 5, 3)
        )
        
        def patched_htd_spec(self, x):
            hl, le = self.hop_length, int(math.ceil(x.shape[-1] / self.hop_length))
            x = demucs.hdemucs.pad1d(x, (hl//2*3, hl//2*3 + le*hl - x.shape[-1]), mode="reflect")
            return demucs.spec.spectro(x, self.nfft, hl)[..., :-1, 2: 2 + le, :]
        demucs.htdemucs.HTDemucs._spec = patched_htd_spec
        def patched_htd_ispec(self, z, length=None, scale=0):
            hl = self.hop_length // (4**scale)
            *other, F, T, _2 = z.shape
            z_padded_f = torch.cat([z, torch.zeros(*other, 1, T, 2).to(z)], dim=-3)
            z_padded_t = torch.cat([torch.zeros(*other, F+1, 2, 2).to(z), z_padded_f, torch.zeros(*other, F+1, 2, 2).to(z)], dim=-2)
            pad, le = hl // 2 * 3, hl * int(math.ceil(length / hl)) + 2 * (hl // 2 * 3)
            return demucs.spec.ispectro(z_padded_t, hl, length=le)[..., pad: pad + length]
        demucs.htdemucs.HTDemucs._ispec = patched_htd_ispec

        def patched_mha_forward(self, q, k, v, **kw):
            am = kw.get('attn_mask') or kw.get('src_mask')
            return manual_mha(q, k, v, self.embed_dim, self.num_heads, self.in_proj_weight, self.in_proj_bias, self.out_proj.weight, self.out_proj.bias, am), None
        nn.MultiheadAttention.forward = patched_mha_forward
        
        from demucs.apply import BagOfModels
        BagOfModels.forward = lambda self, x: self.models[0](x)
    except Exception as e: log(f"Warning: {e}")

def export_model(model_name, output_path):
    try:
        log(f"--- Exporting {model_name} ---")
        from demucs.pretrained import get_model
        model = get_model(model_name)
        while hasattr(model, 'models'): model = model.models[0]
        model.eval(); model.cpu()
        patch_demucs()
        patch_onnx_symbolic()
        wrapper = DemucsWaveformWrapper(model)
        dummy_input = torch.randn(1, 2, 343980).cpu()
        log(f"Tracing and Exporting (Opset 17)...")
        with torch.no_grad():
            traced_model = torch.jit.trace(wrapper, dummy_input, check_trace=False)
            torch.onnx.export(traced_model, dummy_input, output_path, export_params=True, opset_version=17, do_constant_folding=True, input_names=['input'], output_names=['output'], dynamic_axes={'input': {0: 'batch', 2: 'time'}, 'output': {0: 'batch', 1: 'stems', 3: 'time'}})
        log(f"Success! {output_path}")
        onnx.checker.check_model(onnx.load(output_path))
    except Exception as e: log(f"ERROR: {e}\n{traceback.format_exc()}"), sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, default="htdemucs")
    args = parser.parse_args()
    os.makedirs("onnx_exports", exist_ok=True)
    export_model(args.model, os.path.join("onnx_exports", f"{args.model}.onnx"))
