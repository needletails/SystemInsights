#!/bin/sh
set -eu

systemctl --user disable --now system-insights.timer 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/system-insights.service"
rm -f "$HOME/.config/systemd/user/system-insights.timer"
rm -f "$HOME/.local/bin/system-insights"
rm -f "$HOME/.local/bin/system-insights-ui"
rm -f "$HOME/.local/share/applications/com.needletails.systeminsights.desktop"
rm -f "$HOME/.local/share/applications/com.example.systeminsights.desktop"
rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/com.needletails.systeminsights.png"
rm -f "$HOME/.local/share/icons/hicolor/512x512/apps/com.needletails.systeminsights.png"
rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/com.example.systeminsights.png"
rm -f "$HOME/.local/share/icons/hicolor/512x512/apps/com.example.systeminsights.png"
rm -rf "$HOME/.local/share/gnome-shell/extensions/system-insights@needletails.com"
rm -rf "$HOME/.local/share/gnome-shell/extensions/system-insights@example.com"
rm -f "$HOME/.local/share/system-insights/latest.json"
rm -f "$HOME/.local/share/system-insights/latest.snapshot"
rm -f "$HOME/.local/share/system-insights/.snapshot-key"
gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
systemctl --user daemon-reload

printf '%s\n' "Removed System Insights app, collector, timer, panel extension, and desktop entry."
