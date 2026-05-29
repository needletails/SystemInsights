#!/bin/sh
set -eu

ADWAITA_PKG="Apps/ubuntu/SystemInsightsAdwaita"

swift build --package-path "$ADWAITA_PKG" -c debug --product system-insights-ui --static-swift-stdlib

UI_BIN=$(find "$ADWAITA_PKG/.build" -name system-insights-ui -type f -perm -111 2>/dev/null | head -n1)
if [ -z "$UI_BIN" ] || [ ! -x "$UI_BIN" ]; then
    printf 'system-insights-ui binary not found under %s/.build\n' "$ADWAITA_PKG" >&2
    exit 1
fi

install -Dm755 "$UI_BIN" /app/bin/system-insights-ui
install -Dm644 "$ADWAITA_PKG/Resources/com.needletails.systeminsights.desktop" \
    /app/share/applications/com.needletails.systeminsights.desktop
install -Dm644 "$ADWAITA_PKG/Resources/icons/hicolor/256x256/apps/com.needletails.systeminsights.png" \
    /app/share/icons/hicolor/256x256/apps/com.needletails.systeminsights.png
install -Dm644 "$ADWAITA_PKG/Resources/icons/hicolor/512x512/apps/com.needletails.systeminsights.png" \
    /app/share/icons/hicolor/512x512/apps/com.needletails.systeminsights.png
if [ -f VERSION ]; then
    install -Dm644 VERSION /app/share/system-insights/VERSION
fi
