package main

import (
	"fmt"
	"github.com/metin/youtube-stemmer/backend/retrieval"
	"os"
)

func main() {
	url := "https://youtu.be/Yq2jJLswL8I?si=4I_xNHW3oSJ3fLVY"
	outputPath := "test_download.mp4"
	fmt.Printf("Testing download for %s\n", url)
	err := retrieval.DownloadAudio(url, outputPath)
	if err != nil {
		fmt.Printf("Download failed: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("Download succeeded!")
}
