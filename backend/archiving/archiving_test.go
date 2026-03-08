package archiving

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/go-audio/audio"
	"github.com/go-audio/wav"
)

func TestCreateZip(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "archiving_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	file1 := filepath.Join(tmpDir, "test1.txt")
	file2 := filepath.Join(tmpDir, "test2.txt")
	os.WriteFile(file1, []byte("hello world"), 0644)
	os.WriteFile(file2, []byte("foo bar"), 0644)

	zipPath := filepath.Join(tmpDir, "output.zip")

	t.Run("ZipSuccess", func(t *testing.T) {
		err := CreateZip([]string{file1, file2}, zipPath)
		if err != nil {
			t.Errorf("CreateZip failed: %v", err)
		}

		if _, err := os.Stat(zipPath); os.IsNotExist(err) {
			t.Error("Zip file was not created")
		}
	})

	t.Run("Mp3ZipSuccess", func(t *testing.T) {
		wav1 := filepath.Join(tmpDir, "test1.wav")
		wav2 := filepath.Join(tmpDir, "test2.wav")
		
		createDummyWav(wav1)
		createDummyWav(wav2)

		zipPath := filepath.Join(tmpDir, "output_mp3.zip")
		err := CreateMp3Zip([]string{wav1, wav2}, zipPath)
		if err != nil {
			t.Errorf("CreateMp3Zip failed: %v", err)
		}

		if _, err := os.Stat(zipPath); os.IsNotExist(err) {
			t.Error("Mp3 Zip file was not created")
		}
	})
}

func createDummyWav(path string) {
	f, _ := os.Create(path)
	defer f.Close()
	encoder := wav.NewEncoder(f, 44100, 16, 1, 1)
	data := make([]int, 4410) // 0.1s
	buf := &audio.IntBuffer{Data: data, Format: &audio.Format{NumChannels: 1, SampleRate: 44100}}
	encoder.Write(buf)
	encoder.Close()
}
