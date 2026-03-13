# Implementation Plan: Build and Release Optimization

## Phase 1: Unified Packaging Script
- [ ] Create `scripts/package.py` to handle cross-platform packaging logic.
- [ ] Implement OS detection and platform-specific layout logic.
- [ ] Add dependency fetching (ONNX, yt-dlp) to the script.
- [ ] Test on Linux.

## Phase 2: Enhanced Makefile
- [ ] Update root `Makefile` with `backend`, `frontend`, `build`, and `package` targets.
- [ ] Ensure `make clean` is thorough for both components.

## Phase 3: Workflow Refactoring
- [ ] Refactor `.github/workflows/build.yml` to use `make`.
- [ ] Refactor `.github/workflows/release.yml` to share build logic or use the updated scripts.
- [ ] Ensure release notes extraction remains functional.

## Phase 4: Cleanup and Finalization
- [ ] Remove `scripts/package.sh` and `scripts/package.ps1`.
- [ ] Update `BUILD.md` and `README.md` with new build instructions.
