#!/usr/bin/env bash
# Refreshes per-file symlinks for Apps/macOS/SystemInsightCoreSPM (Xcode SPM wrapper).
# Uses paths relative to DEST so clones and CI work on any machine.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/Apps/macOS/SystemInsightCoreSPM/Sources/SystemInsightCore"
SRC="$ROOT/Sources/SystemInsightCore"
mkdir -p "$DEST"
for f in "$SRC"/*.swift; do
  base=$(basename "$f")
  rel=$(python3 -c 'import os.path, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$f" "$DEST")
  ln -sfn "$rel" "$DEST/$base"
done
echo "Synced $(ls -1 "$DEST"/*.swift 2>/dev/null | wc -l | tr -d ' ') symlinks into SystemInsightCoreSPM."
