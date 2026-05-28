#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PBXPROJ="$ROOT_DIR/Apps/macOS/SystemInsights.xcodeproj/project.pbxproj"
FAILED=0

fail() {
    printf 'release-config: %s\n' "$1" >&2
    FAILED=1
}

case "${GITHUB_EVENT_NAME:-}" in
    release|workflow_dispatch)
        if [ -n "${SPARKLE_FEED_URL:-}" ]; then
            case "$SPARKLE_FEED_URL" in
                *example.com*) fail 'SPARKLE_FEED_URL must not use example.com.' ;;
            esac
        else
            fail 'SPARKLE_FEED_URL is required for release builds.'
        fi

        if [ -z "${SPARKLE_PUBLIC_ED_KEY:-}" ] || [ "${SPARKLE_PUBLIC_ED_KEY#CONFIGURE_}" != "$SPARKLE_PUBLIC_ED_KEY" ]; then
            fail 'SPARKLE_PUBLIC_ED_KEY must be configured for release builds.'
        fi
        ;;
esac

if grep -q 'com.example.systeminsights' "$ROOT_DIR/Apps/ubuntu/SystemInsightsAdwaita/Sources/SystemInsightsAdwaita/SystemInsightsApp.swift"; then
    fail 'Ubuntu app id still uses com.example.systeminsights.'
fi

if grep -q 'system-insights@example.com' "$ROOT_DIR/Apps/ubuntu/gnome-extension@system-insights/metadata.json"; then
    fail 'GNOME extension uuid still uses example.com.'
fi

if grep -qE 'DEVELOPMENT_TEAM = [A-Z0-9]{10};' "$PBXPROJ"; then
    fail 'project.pbxproj must not commit DEVELOPMENT_TEAM; use Signing.local.xcconfig.'
fi

if git -C "$ROOT_DIR" ls-files --error-unmatch \
    Apps/macOS/Configuration/Signing.local.xcconfig >/dev/null 2>&1; then
    fail 'Signing.local.xcconfig must not be tracked by git.'
fi

if git -C "$ROOT_DIR" grep -qE 'DEVELOPMENT_TEAM = [A-Z0-9]{10};' -- '*.pbxproj' 2>/dev/null; then
    fail 'project.pbxproj must not commit DEVELOPMENT_TEAM in tracked source.'
fi

if [ "$FAILED" -ne 0 ]; then
    exit 1
fi

printf '%s\n' 'release-config: OK'
