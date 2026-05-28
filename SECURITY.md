# Security Policy

## Reporting a vulnerability

If you discover a security issue, please report it privately rather than opening a public issue.
Include steps to reproduce, affected platforms (macOS, Ubuntu), and impact.

## Data handling

System Insights stores a local health snapshot on disk:

| Platform | Cache file | Key material |
| --- | --- | --- |
| macOS | App Group `latest.snapshot` and `~/Library/Application Support/SystemInsights/latest.snapshot` | Password-wrapped key in `.snapshot-key-wrap`, or file-based `.snapshot-key` when password protection is off (mode `0600`, directory `0700`) |
| Ubuntu | `~/.local/share/system-insights/latest.snapshot` | Same layout under `~/.local/share/system-insights/` |

Snapshots are **AES-GCM encrypted** at rest.

**Password protection (recommended):** On first launch the macOS menu-bar app or Ubuntu Adwaita dashboard can prompt you to set a cache password. The master key is derived with PBKDF2-SHA256 (600k iterations) and stored only as a wrapped blob in `.snapshot-key-wrap`. The password is not written to disk. You must unlock on each app launch. While the app is running, the macOS widget reads the cache via a session key in the shared Keychain access group; on Ubuntu, the CLI and optional GNOME panel extension use a short-lived `.snapshot-session` file (mode `0600`, removed when the app locks or quits).

**Without password protection:** A random 256-bit key is stored in `.snapshot-key` beside the cache (Linux/Ubuntu) or in the Keychain session (macOS).

**Automation:** Set `SYSTEM_INSIGHTS_CACHE_PASSWORD` for CLI/scheduled `collect` when password protection is enabled.

The cache can contain host identity, process names, socket endpoints, and truncated security log lines.
It does **not** contain packet payloads.

## Privacy controls

- Set `SYSTEM_INSIGHTS_DISABLE_LATENCY_PROBE=1` to disable the optional HTTPS latency sample.
- Scheduled Ubuntu collection uses `system-insights collect --quiet` so telemetry is not printed to journal stdout.

## macOS threat model

- The menu-bar **host app** is not App Sandbox–restricted so it can run read-only system probes (`lsof`, `log`, policy tools).
- The **WidgetKit extension** is sandboxed and only reads the shared encrypted cache from the App Group.
- Do not grant packet-capture entitlements without a separate Network Extension design and explicit user consent.

## Production distribution

Release builds must use:

- Real bundle identifiers (`com.needletails.SystemInsights`)
- Developer ID signing and notarization (macOS)
- Production Sparkle HTTPS appcast URL and EdDSA keys (not placeholders)

CI runs `Scripts/check-release-config.sh` to block placeholder update configuration in release builds.
