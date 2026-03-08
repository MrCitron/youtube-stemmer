package stemming

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	ort "github.com/yalue/onnxruntime_go"
	"github.com/go-audio/wav"
	"github.com/go-audio/audio"
)

const (
	SampleRate = 44100
	ChunkSize  = 343980 // Model specific length
)

// Stemmer handles the AI stemming process
type Stemmer struct {
	session *ort.DynamicAdvancedSession
}

// NewStemmer initializes a new ONNX runtime session with the given model path
func NewStemmer(modelPath, sharedLibPath string) (*Stemmer, error) {
	if !ort.IsInitialized() {
		ort.SetSharedLibraryPath(sharedLibPath)
		err := ort.InitializeEnvironment()
		if err != nil {
			return nil, err
		}
	}

	session, err := ort.NewDynamicAdvancedSession(modelPath, []string{"input"}, []string{"output"}, nil)
	if err != nil {
		return nil, err
	}

	return &Stemmer{session: session}, nil
}

// Close releases the ONNX session
func (s *Stemmer) Close() {
	if s.session != nil {
		s.session.Destroy()
	}
}

// SplitAudio splits the audio file into stems
func (s *Stemmer) SplitAudio(inputPath, outputDir string, stemNames []string, onProgress func(float64)) error {
	// 1. Convert to standardized WAV (44100Hz, Stereo, Int16)
	wavPath := filepath.Join(outputDir, "input_standardized.wav")
	cmd := exec.Command("ffmpeg", "-y", "-i", inputPath, "-ar", fmt.Sprintf("%d", SampleRate), "-ac", "2", "-c:a", "pcm_s16le", wavPath)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("ffmpeg conversion failed: %v", err)
	}
	defer os.Remove(wavPath)

	// 2. Read standardized WAV
	f, err := os.Open(wavPath)
	if err != nil {
		return err
	}
	defer f.Close()

	decoder := wav.NewDecoder(f)
	if !decoder.IsValidFile() {
		return fmt.Errorf("invalid WAV file")
	}

	// Read all samples into float32 buffer
	buf, err := decoder.FullPCMBuffer()
	if err != nil {
		return err
	}
	samples := buf.AsFloat32Buffer().Data

	// 3. Process in chunks
	numSamples := len(samples) / 2 // stereo
	numChunks := (numSamples + ChunkSize - 1) / ChunkSize
	
	numStems := len(stemNames)
	// Prepare output buffers for stems
	stems := make([][]float32, numStems)
	for i := range stems {
		stems[i] = make([]float32, numSamples*2)
	}

	for i := 0; i < numChunks; i++ {
		if onProgress != nil {
			onProgress(float64(i) / float64(numChunks))
		}
		
		start := i * ChunkSize
		
		inputData := make([]float32, ChunkSize*2)
		for j := 0; j < ChunkSize; j++ {
			if start+j < numSamples {
				inputData[j*2] = samples[(start+j)*2]
				inputData[j*2+1] = samples[(start+j)*2+1]
			}
		}

		// Run inference
		outputData, err := s.inference(inputData, numStems)
		if err != nil {
			return err
		}

		// Copy output back to stems
		for stemIdx := 0; stemIdx < numStems; stemIdx++ {
			for j := 0; j < ChunkSize; j++ {
				if start+j < numSamples {
					stems[stemIdx][(start+j)*2] = outputData[stemIdx*2*ChunkSize + 0*ChunkSize + j]
					stems[stemIdx][(start+j)*2+1] = outputData[stemIdx*2*ChunkSize + 1*ChunkSize + j]
				}
			}
		}
	}

	if onProgress != nil {
		onProgress(1.0)
	}

	// 4. Save stems
	for i, name := range stemNames {
		outputPath := filepath.Join(outputDir, name+".wav")
		if err := saveWav(outputPath, stems[i], SampleRate); err != nil {
			return err
		}
	}

	return nil
}

func (s *Stemmer) inference(inputData []float32, numStems int) ([]float32, error) {
	// Prepare input tensor [1, 2, ChunkSize]
	// ONNX expects planar layout: [Channel 0 samples..., Channel 1 samples...]
	planarInput := make([]float32, 2*ChunkSize)
	for i := 0; i < ChunkSize; i++ {
		planarInput[i] = inputData[i*2]
		planarInput[i+ChunkSize] = inputData[i*2+1]
	}

	inputShape := ort.NewShape(1, 2, ChunkSize)
	inputTensor, err := ort.NewTensor(inputShape, planarInput)
	if err != nil {
		return nil, err
	}
	defer inputTensor.Destroy()

	// Run inference with nil output to allow dynamic allocation by ONNX Runtime
	outputs := make([]ort.Value, 1)
	err = s.session.Run([]ort.Value{inputTensor}, outputs)
	if err != nil {
		return nil, fmt.Errorf("onnx run failed: %v", err)
	}
	outputValue := outputs[0]
	defer outputValue.Destroy()

	// Retrieve and validate shape
	// Type assertion to access the tensor data and shape
	tensor, ok := outputValue.(*ort.Tensor[float32])
	if !ok {
		return nil, fmt.Errorf("output is not a standard float32 tensor")
	}

	actualShape := tensor.GetShape()
	if actualShape[1] != int64(numStems) {
		return nil, fmt.Errorf("model output dimension mismatch: model provides %d stems, but %d were requested", actualShape[1], numStems)
	}

	outData := tensor.GetData()
	// Return a copy of the data since the tensor will be destroyed
	result := make([]float32, len(outData))
	copy(result, outData)
	return result, nil
}

func saveWav(path string, data []float32, sampleRate int) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	encoder := wav.NewEncoder(f, sampleRate, 16, 2, 1)
	
	// Convert float32 to int16 for WAV
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
