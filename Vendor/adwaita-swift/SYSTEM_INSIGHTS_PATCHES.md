# Vendored Adwaita for Swift

This directory is a copy of:

- Source: https://git.aparoksha.dev/aparoksha/adwaita-swift
- Revision: `d928b464f1d6cc9c08c7a1bd7ea6be7b1cc51ae9`
- Upstream date: 2026-02-17

The copy is used so `SystemInsightsAdwaita` remains buildable with Swift 6.3 and current
Homebrew GLib on macOS. The Swift importer no longer exposes two GLib flag values using
the global constant spellings referenced in this upstream revision.

Local compatibility changes:

- `Sources/Adwaita/Model/Signals/SignalData.swift`: use
  `GConnectFlags(rawValue: 1)` instead of `G_CONNECT_AFTER`.
- `Sources/Adwaita/Model/AdwaitaApp.swift`: use
  `GApplicationFlags(rawValue: 0)` instead of `G_APPLICATION_DEFAULT_FLAGS`, and
  `GConnectFlags(rawValue: 1)` instead of `G_CONNECT_AFTER`.

When upstream adopts equivalent typed flag values, this vendored copy can be removed and
the dependency in `Apps/ubuntu/SystemInsightsAdwaita/Package.swift` can return to the
upstream URL and revision.
