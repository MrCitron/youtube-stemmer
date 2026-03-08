package mixing

import (
	"fmt"
	"os"

	"github.com/braheezy/shine-mp3/pkg/mp3"
	"github.com/go-audio/audio"
	"github.com/go-audio/wav"
)

// MixStems combines multiple WAV files into a single output file with specified weights.
func MixStems(stemPaths []string, weights []float64, outputPath string) error {
	if len(stemPaths) != len(weights) {
		return fmt.Errorf("number of stems and weights must match")
	}

	if len(stemPaths) == 0 {
		return fmt.Errorf("no stems to mix")
	}

	var totalSamples int
	var sampleRate int
	var numChannels int

	var mixedData []float32

	for i, path := range stemPaths {
		f, err := os.Open(path)
		if err != nil {
			return fmt.Errorf("failed to open stem %s: %v", path, err)
		}
		defer f.Close()

		decoder := wav.NewDecoder(f)
		if !decoder.IsValidFile() {
			return fmt.Errorf("invalid WAV file: %s", path)
		}

		buf, err := decoder.FullPCMBuffer()
		if err != nil {
			return fmt.Errorf("failed to read stem %s: %v", path, err)
		}

		samples := buf.AsFloat32Buffer().Data
		weight := float32(weights[i])

		if i == 0 {
			sampleRate = decoder.Format().SampleRate
			numChannels = decoder.Format().NumChannels
			totalSamples = len(samples)
			mixedData = make([]float32, totalSamples)
		} else {
			if decoder.Format().SampleRate != sampleRate || decoder.Format().NumChannels != numChannels {
				return fmt.Errorf("stem %s has different format", path)
			}
			if len(samples) < totalSamples {
				totalSamples = len(samples)
				mixedData = mixedData[:totalSamples]
			}
		}

		for j := 0; j < totalSamples; j++ {
			mixedData[j] += samples[j] * weight
		}
	}

	// Determine output format based on extension
	if len(outputPath) > 4 && outputPath[len(outputPath)-4:] == ".mp3" {
		return saveMp3(outputPath, mixedData, sampleRate, numChannels)
	}
	return saveWav(outputPath, mixedData, sampleRate, numChannels)
}

func saveWav(path string, data []float32, sampleRate int, numChannels int) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	encoder := wav.NewEncoder(f, sampleRate, 16, numChannels, 1)
	intData := float32ToInt16(data)
	buf := &audio.IntBuffer{
		Data: intData,
		Format: &audio.Format{
			NumChannels: numChannels,
			SampleRate:  sampleRate,
		},
	}

	if err := encoder.Write(buf); err != nil {
		return err
	}
	return encoder.Close()
}

func saveMp3(path string, data []float32, sampleRate int, numChannels int) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	// shine-mp3 expects int16
	int16Data := make([]int16, len(data))
	for i, v := range data {
		val := int32(v * 32767)
		if val > 32767 { val = 32767 }
		if val < -32768 { val = -32768 }
		int16Data[i] = int16(val)
	}

	// Create new encoder with audio settings
	mp3Encoder := mp3.NewEncoder(sampleRate, numChannels)

	// Set bitrate to 192 kbps (default is 128)
	mp3Encoder.Mpeg.Bitrate = 192
	mp3Encoder.Mpeg.BitrateIndex = 11 // Index for 192kbps in MPEG-I
	
	// Recalculate dependent fields
	avgSlotsPerFrame := (float64(mp3Encoder.Mpeg.GranulesPerFrame) * 576 / (float64(mp3Encoder.Wave.SampleRate))) * (float64(mp3Encoder.Mpeg.Bitrate) * 1000 / float64(mp3Encoder.Mpeg.BitsPerSlot))
	mp3Encoder.Mpeg.WholeSlotsPerFrame = int64(avgSlotsPerFrame)
	mp3Encoder.Mpeg.FracSlotsPerFrame = avgSlotsPerFrame - float64(mp3Encoder.Mpeg.WholeSlotsPerFrame)
	mp3Encoder.Mpeg.Slot_lag = -mp3Encoder.Mpeg.FracSlotsPerFrame

	// Write all the data to the output file
	return mp3Encoder.Write(f, int16Data)
}

func float32ToInt16(data []float32) []int {
	intData := make([]int, len(data))
	for i, v := range data {
		val := int(v * 32767)
		if val > 32767 { val = 32767 }
		if val < -32768 { val = -32768 }
		intData[i] = val
	}
	return intData
}
