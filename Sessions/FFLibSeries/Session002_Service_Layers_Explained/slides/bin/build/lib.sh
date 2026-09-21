#!/usr/bin/env bash
# Shared paths and Marp launcher for the slide toolchain.
# Source this from slides/bin/build.sh and slides/bin/preview.sh.

set -euo pipefail

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SLIDES_DIR="$(cd "${BUILD_DIR}/../.." && pwd)"
DECK="${SLIDES_DIR}/presentation.md"
OUT_DIR="${SLIDES_DIR}/bin/out"
SLIDE_PNG_DIR="${OUT_DIR}/slides"
MARP_CONFIG="${BUILD_DIR}/.marprc.yml"
MARP_BIN="${BUILD_DIR}/node_modules/.bin/marp"

ensure_deps() {
  if [[ -x "${MARP_BIN}" ]]; then
    return
  fi
  echo "Installing slide toolchain (@marp-team/marp-cli)…"
  npm install --prefix "${BUILD_DIR}" --no-fund --no-audit
}

marp() {
  ensure_deps
  "${MARP_BIN}" --config-file "${MARP_CONFIG}" --engine "${BUILD_DIR}/engine.js" "$@"
}
