package main

import (
	"fmt"
	"github.com/metin/youtube-stemmer/backend/stemming"
	"os"
)

func main() {
	modelPath := "models/htdemucs.onnx"
	sharedLibPath := "./libonnxruntime.so"
	inputPath := "test_input.wav"
	outputDir := "test_stems"

	os.MkdirAll(outputDir, 0755)

	stemmer, err := stemming.NewStemmer(modelPath, sharedLibPath)
	if err != nil {
		fmt.Printf("Init failed: %v\n", err)
		return
	}
	defer stemmer.Close()

	fmt.Println("Splitting...")
	err = stemmer.SplitAudio(inputPath, outputDir)
	if err != nil {
		fmt.Printf("Split failed: %v\n", err)
		return
	}
	fmt.Println("Done!")
}
