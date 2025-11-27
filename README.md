# 🖨️ make-bookscan-printable  
Convert scanned / low-contrast book PDFs into crisp, high-contrast, print-ready PDFs.

This project provides a **robust, reproducible workflow** for preparing scanned books, old PDFs, or gray-tinted documents for high-quality printing.  
It is optimized for **WSL (Ubuntu on Windows)** and combines the speed of Linux Ghostscript with the quality of Windows ImageMagick 7.

---

## 🌟 Key Features

### ✔ 0–10 Cleanup Levels  
Choose how aggressively to enhance the page:

- **Level 0** → minimal changes  
- **Level 10** → maximum contrast, whitening, bold text  
- Levels 1–9 → carefully tuned presets in between

### ✔ Trial Mode (Visual Comparison)  
Generate **11 variants** (`0.png` … `10.png`) for *one selected page*.  
This lets you visually choose the best cleanup level *before* processing the whole book.

Example:

```bash
./make_printready_im7.sh mybook.pdf "" 300 0 trial:8
# → produces 0.png..10.png for page 8
```

### ✔ Ghostscript Multithreaded Rasterization

* Fast rendering using all CPU cores
* Produces clean 300-dpi grayscale PNGs using `pnggray`
* More reliable than MuPDF for large books

### ✔ High-Quality Cleanup Using ImageMagick 7

We call **Windows ImageMagick 7 (`convert.exe`)** directly from WSL for:

* `-brightness-contrast`
* `-sigmoidal-contrast`
* `-level`

These operators produce excellent text/line quality compared to GraphicsMagick or IM6.

### ✔ Final PDF Assembly

ImageMagick 7 combines cleaned PNGs into a new, print-ready PDF.

### ✔ Works with problematic PDFs

Some PDFs give repair warnings with MuPDF or Ghostscript.
If needed, simply **open → Save As** in Adobe Acrobat to fix the internal structure.

---

## 📂 Repository Contents

```
make-bookscan-printable/
├── make_printready_im7.sh     # Main script
├── README.md                  # This documentation
├── presets.md                 # (optional) Detailed preset explanation
├── example/                   # (optional) Example input + output
└── .gitignore
```

---

## 🚀 Getting Started

### Requirements

**WSL (Ubuntu)**

```bash
sudo apt install ghostscript
```

**Windows ImageMagick 7**
Install from: [https://imagemagick.org](https://imagemagick.org)

Ensure `convert.exe` is in PATH (WSL can see it via `/mnt/c/...`).

Test it:

```bash
which convert.exe
```

---

## 🛠️ Usage

### Full cleanup:

```bash
./make_printready_im7.sh input.pdf [output.pdf] [dpi] [cleanup_level]
```

Example:

```bash
./make_printready_im7.sh input.pdf cleaned.pdf 300 6
```

This will:

1. Rasterize all pages to grayscale PNG (`pnggray @ 300 dpi`)
2. Clean up each page using preset level 6
3. Reassemble into `cleaned.pdf`

---

## 🔍 Trial Mode (Critical Feature)

Run:

```bash
./make_printready_im7.sh input.pdf "" 300 0 trial:<page>
```

This:

* Rasterizes `<page>` once
* Produces **0.png … 10.png** in the current directory
* Each file uses a different cleanup preset

Preview all 11 images → pick the best → do a full run with that level.

Example:

```bash
./make_printready_im7.sh mybook.pdf "" 300 0 trial:25
# Look at 0.png..10.png
./make_printready_im7.sh mybook.pdf cleaned.pdf 300 7
```

---

## 🧽 Cleanup Presets (0–10)

Cleanup intensity increases from 0 to 10.
Each level uses a tuned combination of:

* `-brightness-contrast BxC`
* `-sigmoidal-contrast A,M%`
* `-level black%,white%`

You can freely edit these inside the script.

For details see: **presets.md**

---

## 🧰 Example Cleanup Effect

```
Level 0: Very mild
Level 5: Clean white background, dark crisp text
Level 10: Maximum whitening + deep text contrast
```

---

## 🛠 Troubleshooting

### 1. “Ghostscript says the PDF is damaged”

Open PDF in **Adobe Acrobat → Save As** → run script again.

### 2. “convert.exe not found”

WSL needs to see:

```
/mnt/c/Program Files/ImageMagick-7.1.1-Q16-HDRI/convert.exe
```

Update the path inside the script if necessary.

### 3. “IM6 or GraphicsMagick gives washed-out results”

This project **uses IM7 only**, because IM6/GM mishandle PNG gamma.

### 4. Output PDF larger than expected

This workflow favors **quality over size**.
You may compress manually with Ghostscript if needed, but note:
when PNG input is already optimized, GS recompression can increase size.

---

## 📜 License

MIT 

---

## 🤝 Contributions

Contributions welcome!
Ideas include:

* Auto-selection of cleanup level
* OCR integration
* Color-page detection
* Add a GUI wrapper
* Homebrew (macOS) compatibility
* Docker image

---

## ❤️ Acknowledgements

* MuPDF / Ghostscript contributors
* ImageMagick community
* WSL team
