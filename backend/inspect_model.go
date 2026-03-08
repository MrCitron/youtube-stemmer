package main

import (
	"fmt"
	ort "github.com/yalue/onnxruntime_go"
	"os"
)

func main() {
	modelPath := "models/htdemucs.onnx"
	sharedLibPath := "./libonnxruntime.so"

	if !ort.IsInitialized() {
		ort.SetSharedLibraryPath(sharedLibPath)
		err := ort.InitializeEnvironment()
		if err != nil {
			fmt.Printf("Error initializing ORT: %v\n", err)
			os.Exit(1)
		}
	}

	inputs, outputs, err := ort.GetInputOutputInfo(modelPath)
	if err != nil {
		fmt.Printf("Error getting info: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Inputs:")
	for _, in := range inputs {
		fmt.Printf("- Name: %s, Shape: %v\n", in.Name, in.Dimensions)
	}

	fmt.Println("Outputs:")
	for _, out := range outputs {
		fmt.Printf("- Name: %s, Shape: %v\n", out.Name, out.Dimensions)
	}
}
