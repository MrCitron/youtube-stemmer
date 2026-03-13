.PHONY: backend frontend build package release clean

# Detect OS
OS := $(shell python3 -c "import platform; print(platform.system())")

# Default target
build: backend frontend

ifeq ($(OS), Darwin)
backend:
	@echo "Building Rust backend for macOS (Universal)..."
	cd backend && rustup target add x86_64-apple-darwin aarch64-apple-darwin
	cd backend && MACOSX_DEPLOYMENT_TARGET=11.0 cargo build --release --target x86_64-apple-darwin
	cd backend && MACOSX_DEPLOYMENT_TARGET=11.0 cargo build --release --target aarch64-apple-darwin
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
	cd frontend && flutter build $(shell python3 -c "import platform; print(platform.system().lower().replace('darwin', 'macos'))") --release

package:
	@echo "Packaging application (Snapshot)..."
	python3 scripts/package.py

release:
	@echo "Packaging application (Release)..."
	python3 scripts/package.py --release

clean:
	@echo "Cleaning project..."
	rm -rf dist/
	rm -rf temp_deps/
	cd backend && cargo clean
	rm -f backend/libbackend.dylib
	cd frontend && flutter clean
