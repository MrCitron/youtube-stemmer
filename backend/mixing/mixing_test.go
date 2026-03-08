package mixing

import (
	"math"
	"os"
	"path/filepath"
	"testing"

	"github.com/go-audio/audio"
	"github.com/go-audio/wav"
)

func TestMixStems(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "mixing_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Helper to create a simple sine wave wav file
	createSineWav := func(path string, freq float64, duration float64, sampleRate int) {
		f, _ := os.Create(path)
		defer f.Close()
		encoder := wav.NewEncoder(f, sampleRate, 16, 1, 1)
		numSamples := int(float64(sampleRate) * duration)
		data := make([]int, numSamples)
		for i := 0; i < numSamples; i++ {
			data[i] = int(math.Sin(2*math.Pi*freq*float64(i)/float64(sampleRate)) * 32767 * 0.5)
		}
		buf := &audio.IntBuffer{Data: data, Format: &audio.Format{NumChannels: 1, SampleRate: sampleRate}}
		encoder.Write(buf)
		encoder.Close()
	}

	sampleRate := 44100
	stem1 := filepath.Join(tmpDir, "stem1.wav")
	stem2 := filepath.Join(tmpDir, "stem2.wav")
	output := filepath.Join(tmpDir, "output.wav")

	createSineWav(stem1, 440, 0.1, sampleRate)
	createSineWav(stem2, 880, 0.1, sampleRate)

	t.Run("MixSuccess", func(t *testing.T) {
		err := MixStems([]string{stem1, stem2}, []float64{1.0, 1.0}, output)
		if err != nil {
			t.Errorf("MixStems failed: %v", err)
		}

		if _, err := os.Stat(output); os.IsNotExist(err) {
			t.Error("Output file was not created")
		}

		// Optional: Read output and verify some values
		f, _ := os.Open(output)
		defer f.Close()
		decoder := wav.NewDecoder(f)
		buf, _ := decoder.FullPCMBuffer()
		samples := buf.AsFloat32Buffer().Data
		if len(samples) == 0 {
			t.Error("Output file is empty")
		}
	})

	t.Run("MixToMp3Success", func(t *testing.T) {
		outputMp3 := filepath.Join(tmpDir, "output.mp3")
		err := MixStems([]string{stem1, stem2}, []float64{1.0, 1.0}, outputMp3)
		if err != nil {
			t.Errorf("MixStems to MP3 failed: %v", err)
		}

		if _, err := os.Stat(outputMp3); os.IsNotExist(err) {
			t.Error("Output MP3 file was not created")
		}
		
		info, _ := os.Stat(outputMp3)
		if info.Size() == 0 {
			t.Error("Output MP3 file is empty")
		}
	})

	t.Run("MismatchedArgs", func(t *testing.T) {
		err := MixStems([]string{stem1}, []float64{1.0, 1.0}, output)
		if err == nil {
			t.Error("Expected error for mismatched arguments")
		}
	})
}
