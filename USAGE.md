# 📘 Usage Guide — make-bookscan-printable

This file explains how to run `make_printready.sh` for both trial and full processing.

---

# 1. Trial Mode (Start Here)

A trial run produces **11 versions** (0.png–10.png) of a single page using cleanup levels from 0 to 10.

Example (page 8):

```bash
./make_printready.sh book.pdf "" 300 0 trial:8 --mode text --scale 50
```

Each of the generated images includes:

- cleanup (level 0–10)
- resize (`--scale`)
- optional threshold (`--mode text`)

Open them side-by-side and select the best level.

---

# 2. Full Run

Once you pick a cleanup level, run:

```bash
./make_printready.sh input.pdf output.pdf dpi cleanup_level [options]
```

Example for a mixed-content book:

```bash
./make_printready.sh book.pdf book_clean.pdf 300 5 --mode mixed --scale 50
```

Example for text-heavy material:

```bash
./make_printready.sh book.pdf book_text.pdf 300 6 --mode text --scale 50
```

---

# 3. Modes

### `--mode mixed` (default)
- Keeps grayscale  
- Good for diagrams, shaded figures, photos  
- No threshold  
- Cleanup + scale

### `--mode text`
- Cleanup + resize + threshold  
- Very crisp black/white  
- Small PDFs  
- May remove grayscale detail

---

# 4. Scaling

Resize percentage after cleanup:

- `--scale 100` → keep full resolution  
- `--scale 50` → default  
- `--scale 40`, `--scale 33` → smaller PDFs  
- `--scale 25` → very compact

Scaling occurs **before** thresholding.

---

# 5. Threshold Behavior

### `--bw-threshold none`
Keep grayscale.

### `--bw-threshold N`
Apply hard threshold (binarize page).

### `--bw-threshold auto` (default)
Mode decides:

| Mode | Threshold |
|------|-----------|
| mixed | none |
| text | 75% |

---

# 6. Cleanup Levels 0–10

See `presets.md` for exact transforms.

General guideline:

| Level | Use Case |
|-------|----------|
| 0–2 | lightly scanned or modern PDFs |
| 3–5 | typical book scans |
| 6–8 | faint or low-contrast scans |
| 9–10 | extremely faded photocopies |

---

# 7. Typical Workflow

1. Run a trial:

   ```bash
   ./make_printready.sh book.pdf "" 300 0 trial:10 --mode mixed --scale 50
   ```

2. Inspect `0.png`–`10.png`

3. Choose a level (e.g., 6)

4. Full cleanup:

   ```bash
   ./make_printready.sh book.pdf book_clean.pdf 300 6 --mode mixed --scale 50
   ```

Done!

---

# 8. Troubleshooting

**Ghostscript damaged PDF**  
Open in Acrobat → Save As.

**img2pdf image too large**  
Use lower DPI or smaller scale.

**magick.exe missing**  
Update path in `MAGICK_EXE`.

