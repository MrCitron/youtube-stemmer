package retrieval

import (
	"os"
	"testing"
	"path/filepath"
)

func TestGetVideoMetadata(t *testing.T) {
	url := "https://www.youtube.com/watch?v=dQw4w9WgXcQ" // Rickroll
	metadata, err := GetVideoMetadata(url)
	if err != nil {
		t.Errorf("GetVideoMetadata failed: %v", err)
	}
	
	expectedTitle := "Rick Astley - Never Gonna Give You Up"
	if metadata == "" {
		t.Error("Expected metadata, got empty string")
	}
	
	if !contains(metadata, expectedTitle) {
		t.Errorf("Expected metadata to contain title %q, got %q", expectedTitle, metadata)
	}
}

func TestDownloadAudio(t *testing.T) {
	url := "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
	tmpDir := t.TempDir()
	outputPath := filepath.Join(tmpDir, "audio.mp4") // youtube-dl often downloads m4a/mp4 container

	err := DownloadAudio(url, outputPath)
	if err != nil {
		t.Errorf("DownloadAudio failed: %v", err)
	}

	info, err := os.Stat(outputPath)
	if err != nil {
		t.Errorf("Output file was not created: %v", err)
	}
	if info.Size() < 1000 {
		t.Errorf("Output file is too small: %d bytes", info.Size())
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s[:len(substr)] == substr || contains(s[1:], substr))
}
