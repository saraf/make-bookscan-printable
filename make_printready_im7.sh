#!/usr/bin/env bash
set -euo pipefail

########################################
# Config
########################################
DPI_DEFAULT=300
GS_THREADS_DEFAULT=$(nproc)

# Path to ImageMagick 7 on Windows; usually just "convert.exe"
CONVERT_EXE="convert.exe"

########################################
# Usage / arguments
########################################
if [ "$#" -lt 1 ]; then
  echo "Usage:"
  echo "  Normal run:"
  echo "    $0 input.pdf [output.pdf] [dpi] [cleanup_level]"
  echo "      cleanup_level: 0 (least aggressive) .. 10 (most aggressive)"
  echo
  echo "  Trial run (single page variants):"
  echo "    $0 input.pdf '' [dpi] [ignored_cleanup_level] trial:<page_number>"
  echo "      Example: $0 book.pdf '' 300 0 trial:8"
  echo "      → renders page 8 once, makes 0.png..10.png variants in current dir"
  exit 1
fi

INPUT_PDF="$1"
BASENAME="$(basename "${INPUT_PDF%.*}")"
OUTPUT_PDF="${2:-${BASENAME}_im7_printready.pdf}"
DPI="${3:-$DPI_DEFAULT}"
CLEANUP_LEVEL="${4:-5}"   # default medium
TRIAL_ARG="${5:-}"

########################################
# Trial detection
########################################
TRIAL_PAGE=0
if [[ -n "$TRIAL_ARG" && "$TRIAL_ARG" == trial:* ]]; then
  TRIAL_PAGE="${TRIAL_ARG#trial:}"
  if ! [[ "$TRIAL_PAGE" =~ ^[0-9]+$ ]]; then
    echo "Invalid trial page: $TRIAL_PAGE (must be a positive integer)" >&2
    exit 1
  fi
  echo "=== TRIAL RUN: page $TRIAL_PAGE (cleanup levels 0..10) ==="
fi

PNG_DIR="${BASENAME}_png"
CLEAN_DIR="${BASENAME}_clean"

########################################
# Tool checks
########################################
if ! command -v gs >/dev/null 2>&1; then
  echo "Error: Ghostscript 'gs' not found in PATH." >&2
  exit 1
fi

if ! command -v "$CONVERT_EXE" >/dev/null 2>&1; then
  echo "Error: '$CONVERT_EXE' not found in PATH." >&2
  echo "Run 'which convert.exe' in WSL and update CONVERT_EXE if needed." >&2
  exit 1
fi

########################################
# Cleanup level -> convert.exe mapping
########################################
apply_cleanup_level() {
  local level="$1"
  local in="$2"
  local out="$3"

  case "$level" in
    0)
      # Almost no change
      "$CONVERT_EXE" "$in" "$out"
      ;;
    1)
      "$CONVERT_EXE" "$in" \
        -brightness-contrast 5x10 \
        "$out"
      ;;
    2)
      "$CONVERT_EXE" "$in" \
        -brightness-contrast 10x20 \
        "$out"
      ;;
    3)
      "$CONVERT_EXE" "$in" \
        -brightness-contrast 10x30 \
        "$out"
      ;;
    4)
      "$CONVERT_EXE" "$in" \
        -brightness-contrast 10x30 \
        -sigmoidal-contrast 8,50% \
        "$out"
      ;;
    5)
      "$CONVERT_EXE" "$in" \
        -brightness-contrast 10x30 \
        -sigmoidal-contrast 12,40% \
        -level 2%,98% \
        "$out"
      ;;
    6)
      "$CONVERT_EXE" "$in" \
        -brightness-contrast 10x40 \
        -sigmoidal-contrast 12,40% \
        -level 2%,98% \
        "$out"
      ;;
    7)
      "$CONVERT_EXE" "$in" \
        -brightness-contrast 10x40 \
        -sigmoidal-contrast 15,45% \
        -level 3%,97% \
        "$out"
      ;;
    8)
      "$CONVERT_EXE" "$in" \
        -brightness-contrast 15x50 \
        -sigmoidal-contrast 18,45% \
        -level 3%,97% \
        "$out"
      ;;
    9)
      "$CONVERT_EXE" "$in" \
        -brightness-contrast 15x50 \
        -sigmoidal-contrast 20,45% \
        -level 4%,96% \
        "$out"
      ;;
    10)
      "$CONVERT_EXE" "$in" \
        -brightness-contrast 20x60 \
        -sigmoidal-contrast 22,40% \
        -level 4%,96% \
        "$out"
      ;;
    *)
      echo "Invalid cleanup level: $level (expected 0–10)" >&2
      return 1
      ;;
  esac
}

########################################
# Trial mode: single page, 0..10 variants
########################################
if [ "$TRIAL_PAGE" -gt 0 ]; then
  echo "Input PDF  : $INPUT_PDF"
  echo "Page       : $TRIAL_PAGE"
  echo "DPI        : $DPI"
  echo

  RAW_PNG="trial_page_${TRIAL_PAGE}_raw.png"

  echo "Step 1: Rasterizing page $TRIAL_PAGE → $RAW_PNG (pnggray @ ${DPI}dpi)..."
  gs -dNOPAUSE -dBATCH \
     -sDEVICE=pnggray -r"$DPI" \
     -dFirstPage="$TRIAL_PAGE" -dLastPage="$TRIAL_PAGE" \
     -sOutputFile="$RAW_PNG" \
     "$INPUT_PDF"

  if [ ! -f "$RAW_PNG" ]; then
    echo "Failed to rasterize page $TRIAL_PAGE." >&2
    exit 1
  fi

  echo "Step 2: Generating cleanup variants 0.png .. 10.png"
  for level in $(seq 0 10); do
    out="${level}.png"
    echo "  Level $level → $out"
    apply_cleanup_level "$level" "$RAW_PNG" "$out"
  done

  echo
  echo "Done. Inspect 0.png .. 10.png and pick your preferred cleanup level."
  echo "Then run a full pass with that level:"
  echo "  $0 \"$INPUT_PDF\" \"\" $DPI <level>"
  exit 0
fi

########################################
# Normal run: all pages, single chosen level
########################################
echo "=== FULL RUN ==="
echo "Input PDF        : $INPUT_PDF"
echo "Output PDF       : $OUTPUT_PDF"
echo "DPI              : $DPI"
echo "Cleanup level    : $CLEANUP_LEVEL (0..10)"
echo "PNG dir          : $PNG_DIR"
echo "Clean dir        : $CLEAN_DIR"
echo "GS threads       : $GS_THREADS_DEFAULT"
echo

mkdir -p "$PNG_DIR" "$CLEAN_DIR"

########################################
# Step 1 — PDF -> PNG (Ghostscript)
########################################
echo "Step 1/3: Rasterizing PDF to pnggray @ ${DPI}dpi..."

gs -dNOPAUSE -dBATCH \
   -sDEVICE=pnggray -r"$DPI" \
   -dNumRenderingThreads="$GS_THREADS_DEFAULT" \
   -sOutputFile="${PNG_DIR}/pg-%04d.png" \
   "$INPUT_PDF"

PNG_COUNT=$(ls "$PNG_DIR"/pg-*.png 2>/dev/null | wc -l || true)
if [ "$PNG_COUNT" -eq 0 ]; then
  echo "No PNG pages were generated. Aborting." >&2
  exit 1
fi
echo "Generated $PNG_COUNT PNG pages."
echo

########################################
# Step 2 — Cleanup each PNG with chosen level
########################################
echo "Step 2/3: Cleaning pages with cleanup level $CLEANUP_LEVEL..."

index=0
for in_file in "$PNG_DIR"/pg-*.png; do
  index=$((index + 1))
  base=$(basename "$in_file")
  out_file="$CLEAN_DIR/$base"

  echo "  [$index/$PNG_COUNT] $base"
  apply_cleanup_level "$CLEANUP_LEVEL" "$in_file" "$out_file"
done

echo "Cleanup complete."
echo

########################################
# Step 3 — Combine cleaned PNGs into PDF (convert.exe)
########################################
echo "Step 3/3: Combining cleaned pages into PDF with ImageMagick 7..."

# We rely on Windows IM7 to build the PDF
# (WSL will pass /mnt/... paths through)
"$CONVERT_EXE" "$CLEAN_DIR"/pg-*.png "$OUTPUT_PDF"

echo
echo "Created print-ready PDF: $OUTPUT_PDF"
echo "=== DONE ==="

