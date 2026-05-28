#!/bin/sh
# Emit Schema/release.json for the current tag (used by CI before uploading to GitHub Releases).
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TAG="${1:?Usage: generate-release-json.sh v0.1.0 [owner/repo]}"
REPO="${2:-needletails/SystemInsights}"
VERSION="${TAG#v}"
OUTPUT="$ROOT_DIR/Schema/release.json"

cat >"$OUTPUT" <<EOF
{
  "version": "$VERSION",
  "downloadURL": "https://github.com/$REPO/releases/latest",
  "releaseNotes": "See GitHub release notes for $TAG.",
  "ubuntuAMD64DownloadURL": "https://github.com/$REPO/releases/download/$TAG/system-insights-ubuntu-amd64-$TAG.tar.gz",
  "ubuntuARM64DownloadURL": "https://github.com/$REPO/releases/download/$TAG/system-insights-ubuntu-arm64-$TAG.tar.gz",
  "macOSARM64DownloadURL": "https://github.com/$REPO/releases/download/$TAG/system-insights-macos-arm64-$TAG.zip"
}
EOF

printf 'Wrote %s\n' "$OUTPUT"
