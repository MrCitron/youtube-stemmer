# Package script for Windows

$ProjectRoot = Get-Location
$PackageDir = "$ProjectRoot\dist\windows"
$BundleDir = "$PackageDir\youtube_stemmer"

Write-Host "Building YouTube Stemmer for Windows..."

# 1. Build Go Backend
Write-Host "Building Go backend..."
cd "$ProjectRoot\backend"
# Note: This assumes a Windows environment with 'make' or manually running go build
# For simplicity, we'll assume the environment is set up.
# GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build -o build/windows/libbackend.dll -buildmode=c-shared main.go
# If we are on Linux cross-compiling:
# make windows

# 2. Build Flutter Frontend
Write-Host "Building Flutter frontend..."
cd "$ProjectRoot\frontend"
flutter build windows --release

# 3. Prepare Package Directory
Write-Host "Preparing package directory..."
if (Test-Path $BundleDir) { Remove-Item -Recurse -Force $BundleDir }
New-Item -ItemType Directory -Path $BundleDir
New-Item -ItemType Directory -Path "$BundleDir\lib"

# Copy Flutter bundle
Copy-Item -Recurse "$ProjectRoot\frontend\build\windows\x64\release\bundle\*" $BundleDir

# Copy Go backend shared library
Copy-Item "$ProjectRoot\backend\build\windows\libbackend.dll" "$BundleDir\lib\"

# Copy ONNX runtime shared library (if exists)
if (Test-Path "$ProjectRoot\backend\onnxruntime.dll") {
    Copy-Item "$ProjectRoot\backend\onnxruntime.dll" "$BundleDir\lib\"
}

# 4. Create ZIP
Write-Host "Creating archive..."
Compress-Archive -Path "$BundleDir\*" -DestinationPath "$PackageDir\youtube_stemmer_windows.zip" -Force

Write-Host "Package created at: $PackageDir\youtube_stemmer_windows.zip"
