package retrieval

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"github.com/kkdai/youtube/v2"
)

// GetVideoMetadata fetches the metadata of a YouTube video
func GetVideoMetadata(url string) (string, error) {
	client := youtube.Client{}
	video, err := client.GetVideo(url)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("Title: %s, Author: %s", video.Title, video.Author), nil
}

// DownloadAudio downloads the audio stream of a YouTube video to the specified path
func DownloadAudio(url, outputPath string, onProgress func(float64)) error {
	fmt.Printf("Go: Starting download for %s\n", url)
	client := youtube.Client{}
	video, err := client.GetVideo(url)
	if err != nil {
		fmt.Printf("Go: GetVideo failed: %v\n", err)
		return err
	}

	formats := video.Formats.WithAudioChannels() // only get formats with audio
	if len(formats) == 0 {
		fmt.Printf("Go: No audio formats found\n")
		return fmt.Errorf("no audio formats found")
	}

	// We pick the first one for simplicity, or we could look for best quality
	format := &formats[0]
	fmt.Printf("Go: Selected format: %v, ContentLength: %d\n", format.ItagNo, format.ContentLength)
	stream, totalSize, err := client.GetStream(video, format)
	if err != nil {
		fmt.Printf("Go: GetStream failed: %v\n", err)
		return err
	}
	defer stream.Close()

	// Ensure the parent directory exists
	parentDir := filepath.Dir(outputPath)
	if err := os.MkdirAll(parentDir, 0755); err != nil {
		return fmt.Errorf("failed to create directory %s: %v", parentDir, err)
	}

	file, err := os.Create(outputPath)
	if err != nil {
		fmt.Printf("Go: Failed to create file %s: %v\n", outputPath, err)
		return err
	}
	defer file.Close()

	fmt.Printf("Go: Copying stream to file with progress...\n")
	
	buffer := make([]byte, 32*1024)
	var downloaded int64
	for {
		n, err := stream.Read(buffer)
		if n > 0 {
			_, writeErr := file.Write(buffer[:n])
			if writeErr != nil {
				return writeErr
			}
			downloaded += int64(n)
			if totalSize > 0 && onProgress != nil {
				onProgress(float64(downloaded) / float64(totalSize))
			}
		}
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
	}

	fmt.Printf("Go: Download complete, wrote %d bytes\n", downloaded)
	return nil
}
