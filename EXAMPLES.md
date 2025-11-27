# 📚 Examples & Recipes — make-bookscan-printable

Here are practical “recipes” for real-world scanned books.

---

# 1. Text-Only Books (Smallest PDFs, Sharpest Text)

### Trial
```bash
./make_printready.sh book.pdf "" 300 0 trial:8 --mode text --scale 50
```

### Full
```bash
./make_printready.sh book.pdf book_text.pdf 300 6 --mode text --scale 50
```

---

# 2. Text + Diagrams (Economics, Math, Engineering)

### Trial
```bash
./make_printready.sh econ.pdf "" 300 0 trial:8 --mode mixed --scale 50
```

### Full
```bash
./make_printready.sh econ.pdf econ_clean.pdf 300 5 --mode mixed --scale 50
```

---

# 3. Books Containing Photos

### Trial
```bash
./make_printready.sh art.pdf "" 300 0 trial:5 --mode mixed --scale 60
```

### Full
```bash
./make_printready.sh art.pdf art_clean.pdf 300 4 --mode mixed --scale 60
```

---

# 4. Very Poor Photocopies / Faded Scans

### Trial
```bash
./make_printready.sh oldbook.pdf "" 300 0 trial:12 --mode text --scale 50 --bw-threshold 80
```

### Full
```bash
./make_printready.sh oldbook.pdf old_clean.pdf 300 8 --mode text --scale 50 --bw-threshold 80
```

---

# 5. Reduce PDF Size Aggressively

```bash
./make_printready.sh bigbook.pdf small.pdf 300 6 --mode text --scale 40
```

---

# 6. High-Quality Archival Mode (Max Quality)

```bash
./make_printready.sh thesis.pdf thesis_archival.pdf 300 3 --mode mixed --scale 100
```

---

# 7. Fastest Lightweight Processing (Many Books)

```bash
for f in *.pdf; do
    ./make_printready.sh "$f" "" 300 5 --mode mixed --scale 40
done
```

