#!/usr/bin/env bash
# Build deck outputs from presentation.md.
# Plumbing (Marp CLI, lockfile, config) lives in slides/bin/build/.

# shellcheck source=./build/lib.sh
source "$(cd "$(dirname "$0")" && pwd)/build/lib.sh"

if [[ ! -f "${DECK}" ]]; then
  echo "Missing ${DECK}" >&2
  exit 1
fi

html_out="${SLIDES_DIR}/presentation.html"
marp "${DECK}" -o "${html_out}"
echo "Wrote ${html_out}"

mkdir -p "${SLIDE_PNG_DIR}"
# Marp writes slide.001.png, slide.002.png, … from the -o basename.
rm -f "${SLIDE_PNG_DIR}"/slide.*.png
marp "${DECK}" --images png -o "${SLIDE_PNG_DIR}/slide.png"
echo "Wrote PNGs in ${SLIDE_PNG_DIR}"

pdf_out="${SLIDES_DIR}/presentation.pdf"
marp "${DECK}" --pdf -o "${pdf_out}"
echo "Wrote ${pdf_out}"
