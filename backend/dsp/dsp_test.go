package dsp

import (
	"math"
	"testing"
)

func TestSTFTRoundTrip(t *testing.T) {
	nfft := 4096
	hop := 1024
	window := HannWindow(nfft)

	// Create a dummy signal: a simple sine wave
	signal := make([]float64, 10000)
	for i := range signal {
		signal[i] = math.Sin(0.1 * float64(i))
	}

	// STFT -> ISTFT
	spec := STFT(signal, nfft, hop, window)
	reconstructedFull := ISTFT(spec, nfft, hop, window)

	// Trim the padding (nfft/2 on each side)
	padLen := nfft / 2
	reconstructed := reconstructedFull[padLen : padLen+len(signal)]

	// Verify perfect reconstruction
	maxDiff := 0.0
	for i := 0; i < len(signal); i++ {
		diff := math.Abs(signal[i] - reconstructed[i])
		if diff > maxDiff {
			maxDiff = diff
		}
	}

	t.Logf("Max Reconstruction Error: %e", maxDiff)
	if maxDiff > 1e-10 {
		t.Errorf("Reconstruction error too high: %e", maxDiff)
	}
}
