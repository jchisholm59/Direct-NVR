#!/bin/sh
# Run this once before the first `docker compose up` (and after any fresh
# clone). docker-compose.yml bind-mounts these files individually so your
# settings/zones/history survive container rebuilds — but if a file doesn't
# already exist on the host, Docker creates the mount point as a directory
# instead of a file, which silently breaks the app. This just makes sure
# they exist first.
set -e
cd "$(dirname "$0")"

[ -f .env ] || { echo "Missing .env — copy .env.example to .env and fill it in first." >&2; exit 1; }

for f in settings.json alerts_history.json rois.json exclusions.json detections_state.json; do
  if [ -d "$f" ]; then
    echo "ERROR: $f exists as a directory, not a file (likely from a prior bad Docker run)." >&2
    echo "Remove it (rm -rf $f) and re-run this script." >&2
    exit 1
  fi
  if [ ! -f "$f" ]; then
    if [ "$f" = "alerts_history.json" ]; then
      echo '[]' > "$f"
    else
      echo '{}' > "$f"
    fi
  fi
done

mkdir -p public/clips

echo "Ready — run: docker compose up -d --build"
