import os
import sys
import shutil
import platform
import subprocess
import argparse
import urllib.request
import tarfile
import zipfile
import re

# --- Configuration ---
ONNX_VERSION = "1.20.1"
ONNX_URLS = {
    "Linux": f"https://github.com/microsoft/onnxruntime/releases/download/v{ONNX_VERSION}/onnxruntime-linux-x64-{ONNX_VERSION}.tgz",
    "Darwin": f"https://github.com/microsoft/onnxruntime/releases/download/v1.19.2/onnxruntime-osx-universal2-1.19.2.tgz", # Newer versions don't have universal2 easily
    "Windows": f"https://github.com/microsoft/onnxruntime/releases/download/v{ONNX_VERSION}/onnxruntime-win-x64-{ONNX_VERSION}.zip"
}

YTDLP_URLS = {
    "Linux": "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux",
    "Darwin": "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos",
    "Windows": "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
}

def get_version(is_release=False):
    """Extracts version from VERSION file or fallback to CHANGELOG.md."""
    version = "unknown"
    if os.path.exists("VERSION"):
        with open("VERSION", "r") as f:
            version = f.read().strip()
    elif os.path.exists("CHANGELOG.md"):
        with open("CHANGELOG.md", 'r') as f:
            for line in f:
                match = re.search(r'## \[([0-9.]+)\]', line)
                if match:
                    version = match.group(1)
                    break
    
    if not is_release:
        try:
            git_hash = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD']).decode().strip()
            return f"{version}_{git_hash}"
        except Exception:
            pass
    return version

def download_file(url, dest):
    print(f"Downloading {url} to {dest}...")
    urllib.request.urlretrieve(url, dest)

def extract_archive(archive_path, extract_to):
    print(f"Extracting {archive_path} to {extract_to}...")
    if archive_path.endswith(".tgz") or archive_path.endswith(".tar.gz"):
        with tarfile.open(archive_path, "r:gz") as tar:
            tar.extractall(path=extract_to)
    elif archive_path.endswith(".zip"):
        with zipfile.open(archive_path, "r") as zip_ref:
            zip_ref.extractall(extract_to)

def find_file(directory, filename):
    for root, dirs, files in os.walk(directory):
        if filename in files:
            return os.path.join(root, filename)
    return None

def package():
    parser = argparse.ArgumentParser(description="Unified packaging script for YouTube Stemmer")
    parser.add_argument("--platform", help="Target platform (Linux, Darwin, Windows)", default=platform.system())
    parser.add_argument("--release", action="store_true", help="Build a release package (no git hash suffix)")
    parser.add_argument("--output-name", help="Custom output filename (without extension)")
    args = parser.parse_args()

    target_os = args.platform
    version = get_version(args.release)
    project_root = os.getcwd()
    dist_dir = os.path.join(project_root, "dist", target_os.lower())
    
    if os.path.exists(dist_dir):
        shutil.rmtree(dist_dir)
    os.makedirs(dist_dir)

    print(f"Packaging YouTube Stemmer {version} for {target_os}...")

    # 1. Dependency Management
    temp_dir = os.path.join(project_root, "temp_deps")
    if not os.path.exists(temp_dir):
        os.makedirs(temp_dir)

    # ONNX Runtime
    onnx_lib_name = {
        "Linux": "libonnxruntime.so",
        "Darwin": "libonnxruntime.dylib",
        "Windows": "onnxruntime.dll"
    }[target_os]

    onnx_path = os.path.join("backend", onnx_lib_name)
    if not os.path.exists(onnx_path):
        archive_name = "onnx_runtime_archive" + (".zip" if target_os == "Windows" else ".tgz")
        archive_path = os.path.join(temp_dir, archive_name)
        download_file(ONNX_URLS[target_os], archive_path)
        extract_dir = os.path.join(temp_dir, "onnx_extracted")
        extract_archive(archive_path, extract_dir)
        found_lib = find_file(extract_dir, onnx_lib_name)
        if found_lib:
            shutil.copy(found_lib, onnx_path)
        else:
            print(f"Error: Could not find {onnx_lib_name} in extracted archive.")
            sys.exit(1)

    # yt-dlp
    ytdlp_bin_name = "yt-dlp.exe" if target_os == "Windows" else "yt-dlp"
    ytdlp_path = os.path.join("backend", ytdlp_bin_name)
    if not os.path.exists(ytdlp_path):
        download_file(YTDLP_URLS[target_os], ytdlp_path)
        if target_os != "Windows":
            os.chmod(ytdlp_path, 0o755)

    # 2. Layout preparation
    if target_os == "Linux":
        bundle_dir = os.path.join(dist_dir, "youtube_stemmer")
        os.makedirs(bundle_dir)
        os.makedirs(os.path.join(bundle_dir, "lib"))
        
        # Copy Flutter bundle
        flutter_bundle = "frontend/build/linux/x64/release/bundle"
        if os.path.exists(flutter_bundle):
            for item in os.listdir(flutter_bundle):
                s = os.path.join(flutter_bundle, item)
                d = os.path.join(bundle_dir, item)
                if os.path.isdir(s):
                    shutil.copytree(s, d, dirs_exist_ok=True)
                else:
                    shutil.copy2(s, d)
        
        # Copy backend libs
        backend_lib = "backend/target/release/libbackend.so"
        if os.path.exists(backend_lib):
            shutil.copy2(backend_lib, os.path.join(bundle_dir, "lib/"))
        else:
            print(f"Error: {backend_lib} not found. Build the backend first.")
            sys.exit(1)
            
        shutil.copy2("backend/libonnxruntime.so", os.path.join(bundle_dir, "lib/"))
        shutil.copy2("backend/yt-dlp", bundle_dir)
        
        # Copy scripts
        for s_file in ["install_launcher.sh", "uninstall.sh", "youtube_stemmer.desktop.template"]:
            shutil.copy2(os.path.join("scripts", s_file), bundle_dir)
            if s_file.endswith(".sh"):
                os.chmod(os.path.join(bundle_dir, s_file), 0o755)
        
        # Archive
        if args.output_name:
            archive_path = os.path.join(dist_dir, f"{args.output_name}.tar.gz")
        else:
            archive_path = os.path.join(dist_dir, f"youtube_stemmer_linux_v{version}.tar.gz")
        
        with tarfile.open(archive_path, "w:gz") as tar:
            tar.add(bundle_dir, arcname="youtube_stemmer")
        print(f"Package created at: {archive_path}")

    elif target_os == "Windows":
        bundle_dir = os.path.join(dist_dir, "youtube_stemmer")
        os.makedirs(bundle_dir)
        
        flutter_bundle = "frontend/build/windows/x64/runner/Release"
        if os.path.exists(flutter_bundle):
            for item in os.listdir(flutter_bundle):
                s = os.path.join(flutter_bundle, item)
                d = os.path.join(bundle_dir, item)
                if os.path.isdir(s):
                    shutil.copytree(s, d, dirs_exist_ok=True)
                else:
                    shutil.copy2(s, d)

        backend_lib = "backend/target/release/backend.dll"
        if os.path.exists(backend_lib):
            shutil.copy2(backend_lib, bundle_dir)
        else:
            print(f"Error: {backend_lib} not found. Build the backend first.")
            sys.exit(1)

        shutil.copy2("backend/onnxruntime.dll", bundle_dir)
        shutil.copy2("backend/yt-dlp.exe", bundle_dir)

        # Archive
        if args.output_name:
            archive_path = os.path.join(dist_dir, f"{args.output_name}.zip")
            shutil.make_archive(archive_path.replace(".zip", ""), 'zip', bundle_dir)
        else:
            archive_path = os.path.join(dist_dir, f"youtube_stemmer_windows_v{version}.zip")
            shutil.make_archive(archive_path.replace(".zip", ""), 'zip', bundle_dir)
        print(f"Package created at: {archive_path}")

    elif target_os == "Darwin":
        # macOS is usually just the .app zip
        app_path = "frontend/build/macos/Build/Products/Release/youtube_stemmer.app"
        if os.path.exists(app_path):
            bundle_dir = os.path.join(dist_dir, "youtube_stemmer.app")
            shutil.copytree(app_path, bundle_dir)
            
            # macOS binary path: youtube_stemmer.app/Contents/MacOS/
            macos_dir = os.path.join(bundle_dir, "Contents/MacOS")
            shutil.copy2("backend/yt-dlp", macos_dir)
            
            # Frameworks (libs)
            frameworks_dir = os.path.join(bundle_dir, "Contents/Frameworks")
            if not os.path.exists(frameworks_dir):
                os.makedirs(frameworks_dir)
            
            # Makefile produces it here for macOS
            backend_lib = "backend/libbackend.dylib"
            if os.path.exists(backend_lib):
                shutil.copy2(backend_lib, frameworks_dir)
            else:
                print(f"Error: {backend_lib} not found. Build the backend first.")
                sys.exit(1)
            
            shutil.copy2("backend/libonnxruntime.dylib", frameworks_dir)

            if args.output_name:
                archive_path = os.path.join(dist_dir, f"{args.output_name}.zip")
            else:
                archive_path = os.path.join(dist_dir, f"youtube_stemmer_macos_v{version}.zip")
            
            # Using zip command on macos to preserve symlinks if any
            subprocess.run(["zip", "-r", archive_path, "youtube_stemmer.app"], cwd=dist_dir)
            print(f"Package created at: {archive_path}")
        else:
            print("Error: macOS .app not found. Build the frontend first.")

    # Cleanup temp
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)

if __name__ == "__main__":
    package()
