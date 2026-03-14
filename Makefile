.PHONY: backend frontend build package release clean dev

# Detect OS
OS := $(shell python3 -c "import platform; print(platform.system())")

# Default target
build: backend frontend

ifeq ($(OS), Darwin)
# Use rustup-managed rustc/cargo to support cross-compilation targets (aarch64).
# Homebrew's rustc only ships x86_64 and would be picked up first otherwise.
RUSTUP_CARGO := $(shell rustup which cargo 2>/dev/null || echo cargo)
RUSTUP_RUSTC := $(shell rustup which rustc 2>/dev/null || echo rustc)

backend:
	@echo "Building Rust backend for macOS (Universal)..."
	rustup target add x86_64-apple-darwin aarch64-apple-darwin
	cd backend && RUSTC=$(RUSTUP_RUSTC) MACOSX_DEPLOYMENT_TARGET=11.0 $(RUSTUP_CARGO) build --release --target x86_64-apple-darwin
	cd backend && RUSTC=$(RUSTUP_RUSTC) MACOSX_DEPLOYMENT_TARGET=11.0 $(RUSTUP_CARGO) build --release --target aarch64-apple-darwin
	cd backend && lipo -create -output libbackend.dylib \
		target/aarch64-apple-darwin/release/libbackend.dylib \
		target/x86_64-apple-darwin/release/libbackend.dylib
else
backend:
	@echo "Building Rust backend for $(OS)..."
	cd backend && cargo build --release
endif

frontend:
	@echo "Building Flutter frontend..."
ifeq ($(OS), Darwin)
	@if [ ! -f backend/libonnxruntime.dylib ]; then \
		echo "Downloading ONNX Runtime for macOS..."; \
		curl -L https://github.com/microsoft/onnxruntime/releases/download/v1.19.2/onnxruntime-osx-universal2-1.19.2.tgz -o temp_onnx.tgz; \
		tar -xzf temp_onnx.tgz; \
		cp onnxruntime-osx-universal2-1.19.2/lib/libonnxruntime.1.19.2.dylib backend/libonnxruntime.dylib; \
		rm -rf onnxruntime-osx-universal2-1.19.2 temp_onnx.tgz; \
	fi
	cp backend/libbackend.dylib frontend/macos/libbackend.dylib
	cp backend/libonnxruntime.dylib frontend/macos/libonnxruntime.dylib
else
	@if [ "$(OS)" = "Linux" ] && [ ! -f backend/libonnxruntime.so ]; then \
		echo "Downloading ONNX Runtime for Linux..."; \
		curl -L https://github.com/microsoft/onnxruntime/releases/download/v1.19.2/onnxruntime-linux-x64-1.19.2.tgz -o temp_onnx.tgz; \
		tar -xzf temp_onnx.tgz; \
		cp onnxruntime-linux-x64-1.19.2/lib/libonnxruntime.so.1.19.2 backend/libonnxruntime.so; \
		rm -rf onnxruntime-linux-x64-1.19.2 temp_onnx.tgz; \
	fi
endif
	cd frontend && flutter build $(shell python3 -c "import platform; print(platform.system().lower().replace('darwin', 'macos'))") --release

package:
	@echo "Packaging application (Snapshot)..."
	python3 scripts/package.py

release:
	@echo "Packaging application (Release)..."
	python3 scripts/package.py --release

dev:
	@echo "Fast dev build + run (native arch, no lipo)..."
	@bash scripts/dev_macos.sh

clean:
	@echo "Cleaning project..."
	rm -rf dist/
	rm -rf temp_deps/
	cd backend && cargo clean
	rm -f backend/libbackend.dylib
	cd frontend && flutter clean
