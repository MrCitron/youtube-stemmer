package main

import (
	"fmt"
	"os"
	"github.com/metin/youtube-stemmer/backend/audio"
	"os/exec"
	"strings"
)

func main() {
	wavPath := "test_input.wav"
	mp3Path := "test_output_192.mp3"

	f, err := os.Create(mp3Path)
	if err != nil {
		fmt.Printf("Create failed: %v\n", err)
		return
	}
	defer f.Close()

	err = audio.EncodeWavToMp3(wavPath, f)
	if err != nil {
		fmt.Printf("Encode failed: %v\n", err)
		return
	}
	f.Close()

	fmt.Println("Encode complete. Verifying bitrate...")

	// Use ffprobe or ffmpeg to check bitrate
	cmd := exec.Command("ffprobe", "-v", "error", "-show_entries", "format=bit_rate", "-of", "default=noprint_wrappers=1:nokey=1", mp3Path)
	out, err := cmd.Output()
	if err != nil {
		fmt.Printf("ffprobe failed: %v\n", err)
		return
	}

	bitrate := strings.TrimSpace(string(out))
	fmt.Printf("Detected Bitrate: %s bps\n", bitrate)
	
	// Convert to kbps
	var bps int
	fmt.Sscanf(bitrate, "%d", &bps)
	fmt.Printf("Detected Bitrate: %d kbps\n", bps / 1000)
}
