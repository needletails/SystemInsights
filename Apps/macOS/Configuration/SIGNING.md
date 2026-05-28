# macOS code signing (local)

The Xcode project does **not** commit your Apple Team ID or provisioning profiles. CI supplies `DEVELOPMENT_TEAM` and certificates via GitHub Actions secrets.

## First-time setup

1. Copy `Signing.local.xcconfig.example` to `Signing.local.xcconfig` in this directory.
2. Set `DEVELOPMENT_TEAM` to your 10-character Team ID.
3. Open `Apps/macOS/SystemInsights.xcodeproj` and, for **SystemInsightsApp** and **SystemInsightsWidgetExtension**, choose **Manual** signing and select your **Mac Development** / **Developer ID** profiles.

`Signing.local.xcconfig` is gitignored and must never be committed.

## App Group cache path

When signed with a team, builds use `$(DEVELOPMENT_TEAM).com.needletails.SystemInsights.shared`. The CLI and Adwaita macOS builds can use the same group via:

```bash
export SYSTEM_INSIGHTS_APP_GROUP='YOUR_TEAM_ID.com.needletails.SystemInsights.shared'
```

Without a team, the app uses the Application Support fallback cache only.
