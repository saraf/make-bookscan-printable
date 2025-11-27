# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to **Semantic Versioning**.

---

## [1.0.0] - 2025-11-27
### Added
- Introduced `make_printready.sh`, a full rewrite of the earlier IM6 script.
- Added **two processing modes**:
  - `mixed` for grayscale-safe cleanup
  - `text` for thresholded black/white output
- Added support for **cleanup presets 0–10** (via `presets.md`).
- Added **trial mode** producing `0.png`–`10.png` for a selected page,
  allowing fast visual selection of cleanup strength.
- Added **scaling** (`--scale N`), defaulting to 50%.
- Added **threshold handling** (`--bw-threshold N|none|auto`).
- Added **parallel cleanup** using multiple `magick.exe` workers.
- Added **timing output** for raster, cleanup, combine, and total time.
- Added comprehensive **README.md**, **USAGE.md**, and **EXAMPLES.md**.

### Changed
- Migrated from deprecated `convert.exe` to **magick.exe** (ImageMagick 7).
- Simplified Ghostscript rasterization and removed unstable
  `-dNumRenderingThreads` (which caused `.putdeviceprops` failures).
- Improved argument parsing and error handling.
- Standardized working directory layout: `<book>_png` and `<book>_clean`.

### Fixed
- Resolved multiple issues with nested cleanup/resize pipelines.
- Ensured reliable PDF assembly using `img2pdf` (avoiding IM7 hangs).
- Fixed mode interactions: `mixed` forces grayscale, `text` uses threshold.

### Notes
- This marks the first stable release of the re-architected toolchain.

