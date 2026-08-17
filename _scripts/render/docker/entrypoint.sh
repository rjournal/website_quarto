#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -eq 0 ]]; then
  printf 'rjournal-render-entrypoint requires a command.\n' >&2
  exit 2
fi

xvfb_log="${RJOURNAL_RENDER_XVFB_LOG:-/work/tmp/render-container-logs/xvfb.log}"
mkdir -p "$(dirname "$xvfb_log")"

Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp > "$xvfb_log" 2>&1 &
xvfb_pid="$!"
trap 'kill "$xvfb_pid" >/dev/null 2>&1 || true' EXIT

ready=0
for _ in {1..50}; do
  if xdpyinfo -display :99 >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! kill -0 "$xvfb_pid" 2>/dev/null; then
    break
  fi
  sleep 0.1
done

if [[ "$ready" != 1 ]]; then
  printf 'Xvfb did not become ready; see %s\n' "$xvfb_log" >&2
  cat "$xvfb_log" >&2 || true
  exit 1
fi

export DISPLAY=:99
exec "$@"
