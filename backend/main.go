package main

/*
#include <stdlib.h>
typedef void (*ProgressCallback)(double progress);

static void callProgressCallback(ProgressCallback cb, double progress) {
    if (cb != NULL) {
        cb(progress);
    }
}
*/
import "C"
import (
	"fmt"
	"strings"
	"unsafe"

	"github.com/metin/youtube-stemmer/backend/archiving"
	"github.com/metin/youtube-stemmer/backend/mixing"
	"github.com/metin/youtube-stemmer/backend/retrieval"
	"github.com/metin/youtube-stemmer/backend/stemming"
)

var globalStemmer *stemming.Stemmer

//export HelloWorld
func HelloWorld() {
	fmt.Println("Hello from Go Shared Library!")
}

//export MixStems
func MixStems(paths *C.char, weights *C.double, count C.int, outputPath *C.char) *C.char {
	goPaths := strings.Split(C.GoString(paths), ";")
	goWeights := make([]float64, int(count))
	
	// Convert C doubles to Go float64
	ptr := unsafe.Pointer(weights)
	for i := 0; i < int(count); i++ {
		goWeights[i] = *(*float64)(unsafe.Pointer(uintptr(ptr) + uintptr(i)*unsafe.Sizeof(*weights)))
	}

	goOutputPath := C.GoString(outputPath)
	err := mixing.MixStems(goPaths, goWeights, goOutputPath)
	if err != nil {
		return C.CString(fmt.Sprintf("Error: %v", err))
	}
	return nil
}

//export CreateZip
func CreateZip(paths *C.char, outputPath *C.char) *C.char {
	goPaths := strings.Split(C.GoString(paths), ";")
	goOutputPath := C.GoString(outputPath)
	err := archiving.CreateZip(goPaths, goOutputPath)
	if err != nil {
		return C.CString(fmt.Sprintf("Error: %v", err))
	}
	return nil
}

//export CreateMp3Zip
func CreateMp3Zip(paths *C.char, outputPath *C.char) *C.char {
	goPaths := strings.Split(C.GoString(paths), ";")
	goOutputPath := C.GoString(outputPath)
	err := archiving.CreateMp3Zip(goPaths, goOutputPath)
	if err != nil {
		return C.CString(fmt.Sprintf("Error: %v", err))
	}
	return nil
}

//export InitStemmer
func InitStemmer(modelPath *C.char, sharedLibPath *C.char) *C.char {
	goModelPath := C.GoString(modelPath)
	goLibPath := C.GoString(sharedLibPath)
	fmt.Printf("Go: Initializing Stemmer with model=%s, lib=%s\n", goModelPath, goLibPath)
	var err error
	globalStemmer, err = stemming.NewStemmer(goModelPath, goLibPath)
	if err != nil {
		fmt.Printf("Go: InitStemmer failed: %v\n", err)
		return C.CString(fmt.Sprintf("Error: %v", err))
	}
	fmt.Printf("Go: Stemmer initialized successfully\n")
	return nil
}

//export SplitAudio
func SplitAudio(inputPath *C.char, outputDir *C.char, stemNames *C.char, cb C.ProgressCallback) *C.char {
	if globalStemmer == nil {
		return C.CString("Error: Stemmer not initialized")
	}
	goInputPath := C.GoString(inputPath)
	goOutputDir := C.GoString(outputDir)
	goStemNames := strings.Split(C.GoString(stemNames), ";")
	fmt.Printf("Go: Starting SplitAudio for %s into %s (stems: %v)\n", goInputPath, goOutputDir, goStemNames)
	
	onProgress := func(p float64) {
		C.callProgressCallback(cb, C.double(p))
	}

	err := globalStemmer.SplitAudio(goInputPath, goOutputDir, goStemNames, onProgress)
	if err != nil {
		fmt.Printf("Go: SplitAudio failed: %v\n", err)
		return C.CString(fmt.Sprintf("Error: %v", err))
	}
	fmt.Printf("Go: SplitAudio completed successfully\n")
	return nil
}

//export GetMetadata
func GetMetadata(url *C.char) *C.char {
	goUrl := C.GoString(url)
	metadata, err := retrieval.GetVideoMetadata(goUrl)
	if err != nil {
		return C.CString(fmt.Sprintf("Error: %v", err))
	}
	return C.CString(metadata)
}

//export DownloadAudio
func DownloadAudio(url *C.char, outputPath *C.char, cb C.ProgressCallback) *C.char {
	goUrl := C.GoString(url)
	goPath := C.GoString(outputPath)
	
	onProgress := func(p float64) {
		C.callProgressCallback(cb, C.double(p))
	}

	err := retrieval.DownloadAudio(goUrl, goPath, onProgress)
	if err != nil {
		return C.CString(fmt.Sprintf("Error: %v", err))
	}
	return nil // Success
}

//export FreeString
func FreeString(str *C.char) {
	C.free(unsafe.Pointer(str))
}

func main() {
	// Required for c-shared build
}
