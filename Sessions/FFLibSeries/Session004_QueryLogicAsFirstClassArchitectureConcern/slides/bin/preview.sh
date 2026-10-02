#!/usr/bin/env bash
# Live Marp server. Reloads when presentation.md changes.
# Cursor's HTML preview of presentation.html does not auto-refresh.
# Port defaults to 8080 (Marp's PORT). If that listen is taken, the next free port wins.

# shellcheck source=./build/lib.sh
source "$(cd "$(dirname "$0")" && pwd)/build/lib.sh"

port_in_use() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

PORT="${PORT:-8080}"
if port_in_use "${PORT}"; then
  requested="${PORT}"
  PORT=""
  for try in $(seq $((requested + 1)) $((requested + 20))); do
    if ! port_in_use "${try}"; then
      PORT="${try}"
      break
    fi
  done
  if [[ -z "${PORT}" ]]; then
    echo "No free port found between $((requested + 1)) and $((requested + 20))." >&2
    exit 1
  fi
  echo "Port ${requested} is in use; using ${PORT} instead."
fi
export PORT

echo
echo "Leave this running, then open:"
echo "  http://localhost:${PORT}/presentation.md"
echo
echo "Use a real browser or Cursor Simple Browser on that URL."
echo "Saving presentation.md reloads the deck.  Ctrl+C to stop."
echo

marp --server --html "${SLIDES_DIR}"
