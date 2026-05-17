#!/usr/bin/env bash
# Starts the youtube-clipper backend (port 3001) and frontend (port 3000)
# in the same terminal. Ctrl+C kills both.

set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "==> Checking prerequisites..."
for cmd in bun yt-dlp ffmpeg; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing '$cmd'. Install with: brew install bun yt-dlp ffmpeg" >&2
    exit 1
  fi
done

# Free up ports if something is already listening
for port in 3000 3001; do
  pid=$(lsof -ti tcp:"$port" || true)
  if [ -n "$pid" ]; then
    echo "==> Killing existing process on port $port (pid $pid)"
    kill -9 $pid || true
  fi
done

echo "==> Installing deps (only if needed)..."
[ -d "$ROOT/backend/node_modules" ]  || (cd "$ROOT/backend"  && bun install)
[ -d "$ROOT/frontend/node_modules" ] || (cd "$ROOT/frontend" && bun install)

cleanup() {
  echo
  echo "==> Shutting down..."
  kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
  wait 2>/dev/null || true
  exit 0
}
trap cleanup INT TERM

echo "==> Starting backend on http://localhost:3001"
(cd "$ROOT/backend" && bun run src/index.ts) &
BACKEND_PID=$!

echo "==> Starting frontend on http://localhost:3000"
(cd "$ROOT/frontend" && bun run dev) &
FRONTEND_PID=$!

# Wait for the frontend to be reachable, then open the browser once.
(
  for _ in $(seq 1 60); do
    if curl -sSf -o /dev/null http://localhost:3000; then
      open http://localhost:3000 2>/dev/null || true
      exit 0
    fi
    sleep 1
  done
) &

echo
echo "================================================"
echo "  Opening http://localhost:3000 in your browser"
echo "  Press Ctrl+C to stop both servers"
echo "================================================"
echo

wait
