package archiving

import (
	"archive/zip"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/metin/youtube-stemmer/backend/audio"
)

// CreateZip packages multiple files into a single ZIP archive.
func CreateZip(files []string, zipPath string) error {
	newZipFile, err := os.Create(zipPath)
	if err != nil {
		return err
	}
	defer newZipFile.Close()

	zipWriter := zip.NewWriter(newZipFile)
	defer zipWriter.Close()

	for _, file := range files {
		if err := addFileToZip(zipWriter, file, false); err != nil {
			return err
		}
	}

	return nil
}

// CreateMp3Zip packages multiple WAV files into a single ZIP archive, converting them to MP3.
func CreateMp3Zip(files []string, zipPath string) error {
	newZipFile, err := os.Create(zipPath)
	if err != nil {
		return err
	}
	defer newZipFile.Close()

	zipWriter := zip.NewWriter(newZipFile)
	defer zipWriter.Close()

	for _, file := range files {
		if err := addFileToZip(zipWriter, file, true); err != nil {
			return err
		}
	}

	return nil
}

func addFileToZip(zipWriter *zip.Writer, filename string, encodeToMp3 bool) error {
	var entryName string
	if encodeToMp3 {
		entryName = strings.TrimSuffix(filepath.Base(filename), filepath.Ext(filename)) + ".mp3"
	} else {
		entryName = filepath.Base(filename)
	}

	writer, err := zipWriter.Create(entryName)
	if err != nil {
		return err
	}

	if encodeToMp3 {
		return audio.EncodeWavToMp3(filename, writer)
	}

	fileToZip, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer fileToZip.Close()

	_, err = io.Copy(writer, fileToZip)
	return err
}
