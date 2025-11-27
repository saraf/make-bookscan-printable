#!/usr/bin/env bash
set -euo pipefail

############################################################
# Defaults / config
############################################################
DPI_DEFAULT=300
GS_THREADS_DEFAULT=$(nproc)

# ImageMagick 7 entry point on Windows
MAGICK_EXE="magick.exe"

# Parallel cleanup jobs
CLEAN_JOBS_DEFAULT=6

# Default cleanup level
CLEANUP_LEVEL_DEFAULT=5

# Default mode
MODE_DEFAULT="mixed"   # "mixed" or "text"

# Default resize scale (percentage)
SCALE_DEFAULT=50

# Threshold default ("auto" = mode chooses)
BW_THRESHOLD_DEFAULT="auto"

############################################################
# Usage
############################################################
print_usage() {
  cat <<EOF
Usage:
  $0 input.pdf [output.pdf] [dpi] [cleanup_level] [trial:page] [options]

Options:
  --mode text|mixed
      text  : cleanup + resize + threshold (best for text)
      mixed : cleanup + resize, no threshold (best for grayscale/photos)
      default: $MODE_DEFAULT

  --scale N
      Resize percentage after cleanup (e.g. 50, 40, 100)
      default: $SCALE_DEFAULT

  --bw-threshold N|none
      N     : apply -threshold N%
      none  : keep grayscale
      default: auto (chosen by mode)

Trial run:
  $0 input.pdf "" dpi 0 trial:<page> [options]

EOF
}

############################################################
# Parse args
############################################################
if [ "$#" -lt 1 ]; then
  print_usage
  exit 1
fi

INPUT_PDF=""
OUTPUT_PDF=""
DPI="$DPI_DEFAULT"
CLEANUP_LEVEL="$CLEANUP_LEVEL_DEFAULT"
TRIAL_ARG=""

MODE="$MODE_DEFAULT"
SCALE="$SCALE_DEFAULT"
BW_THRESHOLD="$BW_THRESHOLD_DEFAULT"
BW_SET_EXPLICIT=0

pos_index=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      shift
      MODE="$1"
      ;;
    --mode=*)
      MODE="${1#--mode=}"
      ;;
    --scale)
      shift
      SCALE="$1"
      ;;
    --scale=*)
      SCALE="${1#--scale=}"
      ;;
    --bw-threshold)
      shift
      BW_THRESHOLD="$1"
      BW_SET_EXPLICIT=1
      ;;
    --bw-threshold=*)
      BW_THRESHOLD="${1#--bw-threshold=}"
      BW_SET_EXPLICIT=1
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      case "$pos_index" in
        0) INPUT_PDF="$1" ;;
        1) OUTPUT_PDF="$1" ;;
        2) DPI="$1" ;;
        3) CLEANUP_LEVEL="$1" ;;
        4) TRIAL_ARG="$1" ;;
      esac
      pos_index=$((pos_index + 1))
      ;;
  esac
  shift
done

if [ -z "$INPUT_PDF" ]; then
  echo "Error: input.pdf missing" >&2
  exit 1
fi

BASENAME="$(basename "${INPUT_PDF%.*}")"
if [ -z "${OUTPUT_PDF:-}" ] || [ "$OUTPUT_PDF" = "\"\"" ]; then
  OUTPUT_PDF="${BASENAME}_im7_printready.pdf"
fi

############################################################
# Validate mode/scale/threshold
############################################################
case "$MODE" in
  text|mixed) ;;
  *)
    echo "Invalid --mode (expected text|mixed)" >&2
    exit 1
    ;;
esac

if ! [[ "$SCALE" =~ ^[0-9]+$ ]] || [ "$SCALE" -le 0 ]; then
  echo "Error: --scale must be positive integer" >&2
  exit 1
fi

# auto threshold: mode decides
if [ "$BW_THRESHOLD" = "auto" ]; then
  if [ "$MODE" = "text" ]; then
    BW_THRESHOLD="75"
  else
    BW_THRESHOLD="none"
  fi
fi

# mixed mode forces no threshold
if [ "$MODE" = "mixed" ] && [ "$BW_THRESHOLD" != "none" ]; then
  echo "Note: --mode mixed forces grayscale (no threshold)" >&2
  BW_THRESHOLD="none"
fi

############################################################
# Trial detection
############################################################
TRIAL_PAGE=0
if [[ "$TRIAL_ARG" == trial:* ]]; then
  TRIAL_PAGE="${TRIAL_ARG#trial:}"
  if ! [[ "$TRIAL_PAGE" =~ ^[0-9]+$ ]]; then
    echo "Invalid trial page: $TRIAL_PAGE" >&2
    exit 1
  fi
  echo "=== TRIAL RUN: page $TRIAL_PAGE ==="
fi

SCRIPT_START=$(date +%s)

PNG_DIR="${BASENAME}_png"
CLEAN_DIR="${BASENAME}_clean"

############################################################
# Tool checks
############################################################
command -v gs >/dev/null || { echo "Ghostscript not found"; exit 1; }
command -v "$MAGICK_EXE" >/dev/null || {
  echo "magick.exe not in PATH"; exit 1;
}

############################################################
# Cleanup level -> magick operations
############################################################
apply_cleanup_level() {
  local level="$1" in="$2" out="$3"

  case "$level" in
    0) "$MAGICK_EXE" "$in" "$out" ;;
    1) "$MAGICK_EXE" "$in" -brightness-contrast 5x10 "$out" ;;
    2) "$MAGICK_EXE" "$in" -brightness-contrast 10x20 "$out" ;;
    3) "$MAGICK_EXE" "$in" -brightness-contrast 10x30 "$out" ;;
    4) "$MAGICK_EXE" "$in" -brightness-contrast 10x30 -sigmoidal-contrast 8,50% "$out" ;;
    5) "$MAGICK_EXE" "$in" -brightness-contrast 10x30 -sigmoidal-contrast 12,40% -level 2%,98% "$out" ;;
    6) "$MAGICK_EXE" "$in" -brightness-contrast 10x40 -sigmoidal-contrast 12,40% -level 2%,98% "$out" ;;
    7) "$MAGICK_EXE" "$in" -brightness-contrast 10x40 -sigmoidal-contrast 15,45% -level 3%,97% "$out" ;;
    8) "$MAGICK_EXE" "$in" -brightness-contrast 15x50 -sigmoidal-contrast 18,45% -level 3%,97% "$out" ;;
    9) "$MAGICK_EXE" "$in" -brightness-contrast 15x50 -sigmoidal-contrast 20,45% -level 4%,96% "$out" ;;
    10) "$MAGICK_EXE" "$in" -brightness-contrast 20x60 -sigmoidal-contrast 22,40% -level 4%,96% "$out" ;;
    *)
      echo "Invalid cleanup level: $level" >&2
      exit 1
      ;;
  esac
}

############################################################
# Post-process (resize + threshold)
############################################################
post_process_page_inplace() {
  local file="$1"

  local resize_args=()
  if [ "$SCALE" -ne 100 ]; then
    resize_args=(-filter point -resize "${SCALE}%")
  fi

  if [ "$BW_THRESHOLD" = "none" ]; then
    if [ "${#resize_args[@]}" -gt 0 ]; then
      "$MAGICK_EXE" "$file" "${resize_args[@]}" "$file"
    fi
  else
    if [ "${#resize_args[@]}" -gt 0 ]; then
      "$MAGICK_EXE" "$file" "${resize_args[@]}" -threshold "${BW_THRESHOLD}%" "$file"
    else
      "$MAGICK_EXE" "$file" -threshold "${BW_THRESHOLD}%" "$file"
    fi
  fi
}

############################################################
# TRIAL MODE
############################################################
if [ "$TRIAL_PAGE" -gt 0 ]; then
  RAW_PNG="trial_raw.png"

  echo "Rasterizing trial page..."
  gs -dNOPAUSE -dBATCH \
     -sDEVICE=pnggray -r"$DPI" \
     -dFirstPage="$TRIAL_PAGE" -dLastPage="$TRIAL_PAGE" \
     -sOutputFile="$RAW_PNG" \
     "$INPUT_PDF"

  echo "Generating trials 0.png..10.png"
  for lvl in {0..10}; do
    tmp="tmp_${lvl}.png"
    out="${lvl}.png"

    apply_cleanup_level "$lvl" "$RAW_PNG" "$tmp"
    cp "$tmp" "$out"
    post_process_page_inplace "$out"
    rm "$tmp"
    echo "  → $out"
  done

  echo "Trial mode complete."
  exit 0
fi

############################################################
# FULL RUN — Step 1: Rasterize entire PDF
############################################################
echo "=== FULL RUN ==="
echo "Input: $INPUT_PDF"
echo "Output: $OUTPUT_PDF"
echo "Mode: $MODE"
echo "Scale: $SCALE%"
echo "BW threshold: $BW_THRESHOLD"
echo

mkdir -p "$PNG_DIR" "$CLEAN_DIR"

echo "Step 1/3 — Rasterizing PDF..."

STEP1_START=$(date +%s)

gs -dNOPAUSE -dBATCH \
   -sDEVICE=pnggray -r"$DPI" \
   -sOutputFile="${PNG_DIR}/pg-%04d.png" \
   "$INPUT_PDF"

STEP1_END=$(date +%s)

PNG_COUNT=$(ls "$PNG_DIR"/pg-*.png 2>/dev/null | wc -l || true)
if [ "$PNG_COUNT" -eq 0 ]; then
  echo "No PNG pages generated, aborting." >&2
  exit 1
fi

echo "Generated $PNG_COUNT PNG pages."
echo "Step 1 time: $((STEP1_END - STEP1_START))s"
echo

############################################################
# FULL RUN — Step 2: Cleanup + resize + optional threshold
############################################################
echo "Step 2/3 — Cleaning pages (level $CLEANUP_LEVEL, $CLEAN_JOBS_DEFAULT parallel jobs)..."

STEP2_START=$(date +%s)

mapfile -t PAGES < <(ls "$PNG_DIR"/pg-*.png | sort)
TOTAL=${#PAGES[@]}
if [ "$TOTAL" -eq 0 ]; then
  echo "No PNG pages found in $PNG_DIR, aborting." >&2
  exit 1
fi

running=0
index=0

for in_file in "${PAGES[@]}"; do
  index=$((index + 1))
  base="$(basename "$in_file")"
  out_file="$CLEAN_DIR/$base"

  echo "  [$index/$TOTAL] $base"

  (
    # cleanup
    apply_cleanup_level "$CLEANUP_LEVEL" "$in_file" "$out_file"
    # resize + threshold
    post_process_page_inplace "$out_file"
  ) &

  running=$((running + 1))
  if (( running >= CLEAN_JOBS_DEFAULT )); then
    wait -n
    running=$((running - 1))
  fi
done

wait

STEP2_END=$(date +%s)
echo "Step 2 time: $((STEP2_END - STEP2_START))s"
echo

############################################################
# FULL RUN — Step 3: Combine cleaned PNGs with img2pdf
############################################################
echo "Step 3/3 — Combining pages into PDF with img2pdf..."

STEP3_START=$(date +%s)

if ! command -v img2pdf >/dev/null 2>&1; then
  echo "Error: img2pdf not found. Install with:" >&2
  echo "  sudo apt install img2pdf" >&2
  exit 1
fi

img2pdf --pillow-limit-break "$CLEAN_DIR"/pg-*.png -o "$OUTPUT_PDF"

STEP3_END=$(date +%s)
SCRIPT_END=$(date +%s)

echo
echo "Created print-ready PDF: $OUTPUT_PDF"
echo "Step 3 time: $((STEP3_END - STEP3_START))s"
echo "Total time: $((SCRIPT_END - SCRIPT_START))s"
echo "=== DONE ==="
