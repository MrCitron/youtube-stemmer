package dsp

import (
	"math"
	"math/cmplx"
	"github.com/madelynnblue/go-dsp/fft"
)

// HannWindow generates a Hann window of length n.
func HannWindow(n int) []float64 {
	window := make([]float64, n)
	for i := 0; i < n; i++ {
		window[i] = 0.5 * (1 - math.Cos(2*math.Pi*float64(i)/float64(n)))
	}
	return window
}

// STFT performs the Short-Time Fourier Transform.
func STFT(signal []float64, nfft, hop int, window []float64) [][]complex128 {
	// Center padding (like PyTorch center=True)
	padLen := nfft / 2
	paddedSignal := make([]float64, len(signal)+2*padLen)
	copy(paddedSignal[padLen:], signal)
	// Reflection padding or zero padding? PyTorch uses reflection by default but zeros is simpler.
	// For now let's use zeros as it's common for source separation.

	numFrames := (len(paddedSignal)-nfft)/hop + 1
	spectrogram := make([][]complex128, numFrames)
	for i := 0; i < numFrames; i++ {
		frame := make([]complex128, nfft)
		start := i * hop
		for j := 0; j < nfft; j++ {
			frame[j] = complex(paddedSignal[start+j]*window[j], 0)
		}
		full := fft.FFT(frame)
		spectrogram[i] = full[:nfft/2+1]
	}
	return spectrogram
}

// ISTFT performs the Inverse Short-Time Fourier Transform with perfect reconstruction (WOLA).
func ISTFT(spectrogram [][]complex128, nfft, hop int, window []float64) []float64 {
	numFrames := len(spectrogram)
	outputLen := (numFrames-1)*hop + nfft
	out := make([]float64, outputLen)
	windowSum := make([]float64, outputLen)

	for i := 0; i < numFrames; i++ {
		// 1. Get the full complex spectrum (reconstruct Hermitian symmetry)
		fullSpectrum := make([]complex128, nfft)
		copy(fullSpectrum, spectrogram[i])
		for j := 1; j < nfft/2; j++ {
			fullSpectrum[nfft-j] = cmplx.Conj(spectrogram[i][j])
		}

		// 2. IFFT
		frameTime := fft.IFFT(fullSpectrum)

		// 3. Weighted Overlap-Add (WOLA)
		start := i * hop
		for j := 0; j < nfft; j++ {
			if start+j < outputLen {
				val := real(frameTime[j]) * window[j]
				out[start+j] += val
				windowSum[start+j] += window[j] * window[j]
			}
		}
	}

	// 4. Normalization
	for i := 0; i < outputLen; i++ {
		if windowSum[i] > 1e-10 {
			out[i] /= windowSum[i]
		}
	}

	return out
}
