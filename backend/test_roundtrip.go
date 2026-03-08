package main

import (
	"fmt"
	"os"
	"github.com/go-audio/wav"
	"github.com/go-audio/audio"
)

func main() {
	inputPath := "test_input.wav"
	outputPath := "test_roundtrip.wav"

	f, err := os.Open(inputPath)
	if err != nil {
		fmt.Printf("Open failed: %v\n", err)
		return
	}
	defer f.Close()

	decoder := wav.NewDecoder(f)
	buf, err := decoder.FullPCMBuffer()
	if err != nil {
		fmt.Printf("Read failed: %v\n", err)
		return
	}
	samples := buf.AsFloat32Buffer().Data

	// Save back
	if err := saveWav(outputPath, samples, 44100); err != nil {
		fmt.Printf("Save failed: %v\n", err)
		return
	}
	fmt.Println("Roundtrip complete!")
}

func saveWav(path string, data []float32, sampleRate int) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	encoder := wav.NewEncoder(f, sampleRate, 16, 2, 1)
	intData := make([]int, len(data))
	for i, v := range data {
		val := int(v * 32767)
		if val > 32767 { val = 32767 }
		if val < -32768 { val = -32768 }
		intData[i] = val
	}
	buf := &audio.IntBuffer{
		Data: intData,
		Format: &audio.Format{
			NumChannels: 2,
			SampleRate:  sampleRate,
		},
	}
	if err := encoder.Write(buf); err != nil {
		return err
	}
	return encoder.Close()
}
