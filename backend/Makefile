# Makefile for Go Shared Library (FFI)

MODULE_NAME=github.com/metin/youtube-stemmer/backend
BINARY_NAME=libbackend

# Go binary path (from mise)
GO=/home/metin/.local/share/mise/installs/go/1.26.1/bin/go

.PHONY: all clean linux windows android macos ios

all: linux windows android

linux:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=1 $(GO) build -o build/linux/$(BINARY_NAME).so -buildmode=c-shared main.go
	cp build/linux/$(BINARY_NAME).so .
	cp build/linux/$(BINARY_NAME).h .

windows:
	# Requires mingw-w64
	GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc $(GO) build -o build/windows/$(BINARY_NAME).dll -buildmode=c-shared main.go

android:
	# Requires Android NDK and CC set to the right toolchain
	# This is a template, as the NDK path and toolchain vary
	# GOOS=android GOARCH=arm64 CGO_ENABLED=1 CC=$(NDK_PATH)/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android33-clang $(GO) build -o build/android/$(BINARY_NAME).so -buildmode=c-shared main.go
	@echo "Android build requires NDK configured. Please see documentation."

macos:
	# Requires a Mac or osxcross
	# GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 $(GO) build -o build/macos/$(BINARY_NAME).dylib -buildmode=c-shared main.go
	@echo "macOS build requires a Mac or osxcross toolchain."

ios:
	# Requires a Mac
	# GOOS=ios GOARCH=arm64 CGO_ENABLED=1 $(GO) build -o build/ios/$(BINARY_NAME).a -buildmode=c-archive main.go
	@echo "iOS build requires a Mac and is usually built as c-archive (.a)."

clean:
	rm -rf build/

dist: all
	# Linux
	mkdir -p ../frontend/linux/
	cp build/linux/$(BINARY_NAME).so ../frontend/linux/
	# Windows
	mkdir -p ../frontend/windows/
	cp build/windows/$(BINARY_NAME).dll ../frontend/windows/
	# Android (template)
	# mkdir -p ../frontend/android/app/src/main/jniLibs/arm64-v8a/
	# cp build/android/$(BINARY_NAME).so ../frontend/android/app/src/main/jniLibs/arm64-v8a/
