package stemming

import (
	"testing"
	"os"
)

func TestStemmerStructure(t *testing.T) {
	modelPath := "../models/htdemucs.onnx"
	sharedLibPath := "../libonnxruntime.so"

	if _, err := os.Stat(sharedLibPath); os.IsNotExist(err) {
		t.Skip("libonnxruntime.so not found")
	}

	if _, err := os.Stat(modelPath); os.IsNotExist(err) {
		t.Skip("model file not found")
	}

	stemmer, err := NewStemmer(modelPath, sharedLibPath)
	if err != nil {
		t.Fatalf("NewStemmer failed: %v", err)
	}
	defer stemmer.Close()

	if stemmer == nil {
		t.Error("Expected stemmer instance, got nil")
	}
}

func TestSplitAudio(t *testing.T) {
	modelPath := "../models/htdemucs.onnx"
	sharedLibPath := "../libonnxruntime.so"
	inputPath := "../test_input.wav"
	outputDir := t.TempDir()

	if _, err := os.Stat(sharedLibPath); os.IsNotExist(err) {
		t.Skip("libonnxruntime.so not found")
	}
	if _, err := os.Stat(modelPath); os.IsNotExist(err) {
		t.Skip("model file not found")
	}
	if _, err := os.Stat(inputPath); os.IsNotExist(err) {
		t.Skip("input file not found")
	}

	stemmer, err := NewStemmer(modelPath, sharedLibPath)
	if err != nil {
		t.Fatalf("NewStemmer failed: %v", err)
	}
	defer stemmer.Close()

	err = stemmer.SplitAudio(inputPath, outputDir, []string{"vocals", "drums", "bass", "other"}, nil)
	if err != nil {
		t.Errorf("SplitAudio failed: %v", err)
	}

	// Check for output files
	stems := []string{"vocals.wav", "drums.wav", "bass.wav", "other.wav"}
	for _, s := range stems {
		path := outputDir + "/" + s
		if _, err := os.Stat(path); os.IsNotExist(err) {
			t.Errorf("Expected output file %s not found", s)
		}
	}
}
