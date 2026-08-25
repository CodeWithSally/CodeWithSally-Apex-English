#!/usr/bin/env bash
# Live Marp server. Reloads when presentation.md changes.
# Cursor's HTML preview of presentation.html does not auto-refresh.

# shellcheck source=./build/lib.sh
source "$(cd "$(dirname "$0")" && pwd)/build/lib.sh"

echo
echo "Leave this running, then open:"
echo "  http://localhost:8080/presentation.md"
echo
echo "Use a real browser or Cursor Simple Browser on that URL."
echo "Saving presentation.md reloads the deck.  Ctrl+C to stop."
echo

marp --server --html "${SLIDES_DIR}"
