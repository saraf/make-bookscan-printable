# 🖨️ make-bookscan-printable

Convert scanned / low-contrast book PDFs into crisp, high-contrast, print-ready PDFs.

This project provides a robust, reproducible workflow for preparing scanned books, old PDFs, or gray-tinted documents for high-quality printing. It is optimized for **WSL (Ubuntu on Windows)** and combines:

- **Ghostscript** (Linux) for fast PDF → image rasterization  
- **ImageMagick 7** (`magick.exe`) for cleanup and enhancement  
- **img2pdf** for reliable, lossless PDF assembly

---

## 🌟 Features

### ✔ Cleanup levels 0–10  
Preset cleanup operations using brightness-contrast, sigmoidal contrast, and levels.  
See `presets.md` for details.

### ✔ Modes: `mixed` (default) and `text`  
- `mixed` → grayscale cleanup, good for images/diagrams  
- `text` → cleanup + threshold for crisp black/white output  

### ✔ Resizing (`--scale N`)  
Post-cleanup downscaling for reduced PDF size.

### ✔ Trial Mode  
Generate `0.png`–`10.png` for a chosen page to pick the ideal cleanup level.

### ✔ Parallel Cleanup  
Processes multiple pages at once via parallel `magick.exe` jobs.

---

## 📂 Files in This Repository

```
make_printready.sh     # Main script
README.md              # Project overview
USAGE.md               # Practical usage guide
EXAMPLES.md            # Recipes for real-world books
CHANGELOG.md           # Notable changes
presets.md             # Cleanup level reference
LICENSE.txt            # License
```

---

## 🚀 Requirements

### On WSL (Ubuntu)
```bash
sudo apt install ghostscript img2pdf
```

### On Windows
Install **ImageMagick 7** (Q16 HDRI recommended).  
Confirm from WSL:

```bash
which magick.exe
```

Update the `MAGICK_EXE` variable in the script if needed.

---

## 🧪 Trial Run

Generate cleaned variants for one page:

```bash
./make_printready.sh book.pdf "" 300 0 trial:10 --mode mixed --scale 50
```

Produces:

```
0.png
1.png
...
10.png
```

Each image includes cleanup, resizing, and threshold behavior.

Pick the best level visually.

---

## 🧼 Full Run

```bash
./make_printready.sh input.pdf output.pdf dpi cleanup_level [options]
```

Example:

```bash
./make_printready.sh book.pdf cleaned.pdf 300 6 --mode mixed --scale 50
```

---

## 🔧 Options

### `--mode text|mixed`
- `mixed` (default): grayscale cleanup, no threshold  
- `text`: cleanup + threshold for sharp black/white output

### `--scale N`
Resize percentage (default `50`).

### `--bw-threshold N|none|auto`
- `none` → keep grayscale  
- `N` → threshold at N%  
- `auto` (default): mode decides (text→75%, mixed→none)

---

## 🧱 Pipeline

1. **Ghostscript** → PNG grayscale pages  
2. **ImageMagick 7** → cleanup + resize + optional threshold  
3. **img2pdf** → fast PDF assembly

---

## 🛠 Troubleshooting

### GS errors about damaged PDFs  
Open in Adobe Acrobat → Save As → retry.

### “Image too large” in img2pdf  
Use lower DPI or smaller scale (e.g., `--scale 40`).

### magick.exe not found  
Update the path in the script.

---

## ❤️ Credits

- Ghostscript developers  
- ImageMagick community  
- img2pdf author

