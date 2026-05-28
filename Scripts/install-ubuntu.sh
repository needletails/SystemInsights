#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BIN_DIR="$HOME/.local/bin"
DATA_DIR="$HOME/.local/share/system-insights"
SYSTEMD_DIR="$HOME/.config/systemd/user"
EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/system-insights@needletails.com"
APPLICATIONS_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor"

if [ "${1:-}" = "--install-deps" ]; then
    if ! command -v apt-get >/dev/null 2>&1 || ! command -v sudo >/dev/null 2>&1; then
        printf '%s\n' "Automatic dependency installation requires Ubuntu apt-get and sudo." >&2
        exit 1
    fi
    sudo apt-get update
    sudo apt-get install -y libadwaita-1-0 libgtk-4-1
fi

if [ -x "$ROOT_DIR/bin/system-insights" ] && [ -x "$ROOT_DIR/bin/system-insights-ui" ]; then
    COLLECTOR_BIN="$ROOT_DIR/bin/system-insights"
    UI_BIN="$ROOT_DIR/bin/system-insights-ui"
else
    swift build --package-path "$ROOT_DIR" -c release --product system-insights
    swift build --package-path "$ROOT_DIR/Apps/ubuntu/SystemInsightsAdwaita" -c release --product system-insights-ui
    COLLECTOR_BIN="$ROOT_DIR/.build/release/system-insights"
    UI_BIN="$ROOT_DIR/Apps/ubuntu/SystemInsightsAdwaita/.build/release/system-insights-ui"
fi

if command -v ldd >/dev/null 2>&1 && ldd "$UI_BIN" 2>/dev/null | grep -q 'not found'; then
    printf '%s\n' "Missing Ubuntu runtime libraries for the graphical app." >&2
    printf '%s\n' "Install automatically with: ./Scripts/install-ubuntu.sh --install-deps" >&2
    printf '%s\n' "Or install manually: sudo apt install libadwaita-1-0 libgtk-4-1" >&2
    exit 1
fi

mkdir -p "$BIN_DIR" "$DATA_DIR" "$SYSTEMD_DIR" "$EXTENSION_DIR" "$APPLICATIONS_DIR" \
    "$ICON_DIR/256x256/apps" "$ICON_DIR/512x512/apps"
chmod 700 "$DATA_DIR"
if [ -f "$ROOT_DIR/VERSION" ]; then
    install -m 644 "$ROOT_DIR/VERSION" "$DATA_DIR/VERSION"
fi
install -m 755 "$COLLECTOR_BIN" "$BIN_DIR/system-insights"
install -m 755 "$UI_BIN" "$BIN_DIR/system-insights-ui"
install -m 644 "$ROOT_DIR/Apps/ubuntu/systemd/system-insights.service" "$SYSTEMD_DIR/system-insights.service"
install -m 644 "$ROOT_DIR/Apps/ubuntu/systemd/system-insights.timer" "$SYSTEMD_DIR/system-insights.timer"
install -m 644 "$ROOT_DIR/Apps/ubuntu/gnome-extension@system-insights/metadata.json" "$EXTENSION_DIR/metadata.json"
install -m 644 "$ROOT_DIR/Apps/ubuntu/gnome-extension@system-insights/extension.js" "$EXTENSION_DIR/extension.js"
install -m 644 "$ROOT_DIR/Apps/ubuntu/gnome-extension@system-insights/stylesheet.css" "$EXTENSION_DIR/stylesheet.css"
install -m 644 "$ROOT_DIR/Apps/ubuntu/SystemInsightsAdwaita/Resources/com.needletails.systeminsights.desktop" \
    "$APPLICATIONS_DIR/com.needletails.systeminsights.desktop"
install -m 644 "$ROOT_DIR/Apps/ubuntu/SystemInsightsAdwaita/Resources/icons/hicolor/256x256/apps/com.needletails.systeminsights.png" \
    "$ICON_DIR/256x256/apps/com.needletails.systeminsights.png"
install -m 644 "$ROOT_DIR/Apps/ubuntu/SystemInsightsAdwaita/Resources/icons/hicolor/512x512/apps/com.needletails.systeminsights.png" \
    "$ICON_DIR/512x512/apps/com.needletails.systeminsights.png"
gtk-update-icon-cache "$ICON_DIR" >/dev/null 2>&1 || true

"$BIN_DIR/system-insights" collect --quiet --output "$DATA_DIR/latest.snapshot"
systemctl --user daemon-reload
systemctl --user enable --now system-insights.timer

printf '%s\n' "Installed the System Insights Adwaita app, collector, and enabled its 10-minute user timer."
printf '%s\n' "Open System Insights from the application launcher or run: system-insights-ui"
printf '%s\n' "Optional panel indicator: gnome-extensions enable system-insights@needletails.com"
