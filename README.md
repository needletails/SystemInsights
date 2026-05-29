# System Insights

**Repository:** [github.com/needletails/SystemInsights](https://github.com/needletails/SystemInsights)

System Insights is a cross-platform performance and security health widget. A shared Swift
engine produces a versioned `InsightSnapshot` JSON document; a macOS menu-bar app and
WidgetKit widget, or a native dashboard built with Adwaita for Swift on macOS and Ubuntu,
display the same health score and recommended action.

## MVP Status

Implemented in this repository:

- `SystemInsightCore`, a Swift 6 package with async metric/security collectors, scoring, mocks, and atomic JSON caching.
- `system-insights`, a Swift CLI that collects live or mock snapshots for scheduled execution.
- A macOS SwiftUI menu-bar application and WidgetKit extension using a shared App Group cache.
- Sparkle 2 update wiring for the directly downloaded macOS application.
- A native macOS and Ubuntu Libadwaita dashboard (`system-insights-ui`) built with [Adwaita for Swift](https://git.aparoksha.dev/aparoksha/adwaita-swift).
- A Ubuntu `systemd --user` timer and native Adwaita dashboard using an encrypted cache at `~/.local/share/system-insights/latest.snapshot`.
- Swift tests, Ubuntu installers, CI, and tagged download-release workflows.

The macOS application runs the full security collection every 10 minutes while running,
updates lightweight telemetry every 5 seconds, refreshes when the active Network framework
path changes (for example, as a VPN tunnel appears), and supports launch at login. Its
menu-bar popover includes a network console that samples RX/TX traffic while visible.
The host also journals a bounded list of visible TCP sessions/listeners and UDP datagram
endpoints exposed to the current user via local socket inspection and shares it with the large
widget. Clicking a placed widget opens an on-demand resizable macOS dashboard with a larger
live traffic graph, searchable socket list, exposure watch, network-actor summary, and
connection activity journal. The dashboard and widget now put measured download/upload
interface speed and latency front and center; the dashboard also retains a rolling average and peak
window while visible. Socket rows and transition events include service hints inferred from
well-known endpoint ports with `PORT MAP` or `HEURISTIC` confidence (no packet inspection). Selecting a socket or transition in
the macOS dashboard opens an investigator sheet with its observable evidence and packet
inspection boundary. Foreground socket polling accelerates while the dashboard is
visible; background polling and WidgetKit publication are deliberately reduced to limit the
monitor's own overhead. Because it collects
host-wide read-only signals and is distributed outside
the App Store, the collector app uses hardened runtime without App Sandbox; the WidgetKit
extension stays sandboxed and only reads the App Group cache. WidgetKit requests a new
timeline every 15 minutes, also receives app reload requests, and never runs live probes
itself; macOS may coalesce frequent widget redraws.

## Naming

User-facing branding is **System Insights**. Swift packages and apps use the `SystemInsights` /
`SystemInsightCore` prefix (the core library keeps singular `Insight` in `SystemInsightCore`).

The checkout directory on disk may still be named `Performance Widget` from the original repo;
SwiftPM does not require the folder name to match. Dependents reference the root package explicitly:

```swift
.package(name: "SystemInsights", path: "../../..")
```

The macOS Xcode project links core code through `Apps/macOS/SystemInsightCoreSPM` so it can use
remote **NeedleTailLogger** without attaching the full monorepo graph to Xcode.

## Repository Layout

```text
Sources/SystemInsightCore/       shared model, collectors, scoring, cache
Sources/SystemInsightsCLI/       scheduled collector executable
Schema/                          portable InsightSnapshot JSON Schema
Apps/macOS/                      SwiftUI app, WidgetKit source, XcodeGen spec
Apps/ubuntu/SystemInsightsAdwaita/ native Swift/Libadwaita dashboard for macOS and Ubuntu
Apps/ubuntu/                     optional GNOME panel extension, systemd timer
Apps/macOS/SystemInsights.xcodeproj/ ready-to-open macOS Xcode project
Vendor/adwaita-swift/            pinned upstream source plus Swift 6.3 compatibility patch
Scripts/                         platform setup and packaging helpers
.github/workflows/               CI and downloadable releases
```

## JSON Contract

Both platforms consume `Schema/insight-snapshot.schema.json`. Every snapshot contains:

- host identity and ISO-8601 generation time
- CPU load, memory pressure, disk usage, and the five busiest processes
- sampled upload/download throughput, active TCP connections, cautious VPN/tunnel state,
  and a bounded feed of visible TCP/UDP socket observations; user interfaces derive
  port-based service hints from these observations without claiming payload inspection
- security findings and scored performance/security issues
- a compact recent security-activity feed from accessible platform logs
- a `0...100` score, `Good` / `Warning` / `Critical` rating, top issue, and recommendations

Generate a predictable sample:

```sh
swift run system-insights collect --mock --output /tmp/latest.json
```

Collect a live snapshot on the current system:

```sh
swift run system-insights collect
```

## Security Checks

The MVP performs user-readable checks only and treats unavailable privileged audit sources as
unavailable rather than asking for administrator access. It detects observable risk signals;
it is not an endpoint detection product or a malware verdict engine.

| Platform | Checks |
| --- | --- |
| macOS | application firewall, FileVault, Gatekeeper, System Integrity Protection, pending updates, unverified high-CPU executables launched from writable locations, recent visible authentication/policy denial log events |
| Ubuntu | UFW state, pending Ubuntu security updates, readable failed-login history, high-CPU processes, world-writable sensitive paths, recent visible journal security warnings |

On macOS, CPU, memory, and network counter sampling use public Darwin and SystemConfiguration
APIs; policy/security checks and process ranking still use read-only system tools where no
equivalent app API exposes host policy state. Linux metrics use `/proc`/`ps` sources. Network
rates are short sampled byte-counter rates rather than long-term usage totals. Latency is a
small throttled HTTPS response probe to `cp.cloudflare.com`, refreshed at most every five
seconds in a visible live monitor and reused for up to thirty seconds for background
snapshots; it is not ICMP ping or passive packet observation. A connected
configured VPN is reported as connected; an active virtual network path identified by Apple's
Network framework is reported as a routed tunnel because macOS does not disclose whether every
third-party Network Extension tunnel is a user VPN or privacy/filter service. The firewall
finding refers specifically to the built-in macOS Application Firewall; it is shown as an
advisory rather than reducing the health score because it does not claim to measure
third-party firewall tools. The app and large widget's socket journal show locally
visible TCP sessions/listeners and UDP datagram endpoints; these observations do not prove
the initiating direction or expose packet contents, and blocked or privileged system-wide
flows require a separately authorized Network Extension content filter. Apple's
[Swift System Metrics](https://github.com/apple/swift-system-metrics) package measures the
monitoring process itself rather than host-wide load or other processes, so it is a suitable
future addition for daemon self-monitoring, not the source of the MVP insight score. The
snapshot cache is **AES-GCM encrypted at rest** with a separate owner-only key file
(`.snapshot-key`), plus `0600` cache files and `0700` directories. Payloads are validated on
read/write, and the macOS widget stays sandboxed while the collector host performs read-only
system probes. See [SECURITY.md](SECURITY.md).

## Develop

Run shared package tests:

```sh
swift test
swift run system-insights collect --mock --output /tmp/system-insights.json
```

### Git hooks and CI safety checks

After cloning, install the **pre-commit** hook once (copies into `.git/hooks`; does not change
global git config):

```sh
sh Scripts/install-git-hooks.sh
```

Every `git commit` then runs `Scripts/verify-safe-to-commit.sh`, which checks staged files and
a `git add -n` preview so signing material, `docs/`, caches, and personal Team IDs cannot slip
into a commit. You can also run it manually before staging:

```sh
sh Scripts/verify-safe-to-commit.sh
git add .
sh Scripts/verify-safe-to-commit.sh
git commit -m "Your message"
```

GitHub Actions **CI** runs the same script on every push and pull request, plus `swift test`,
builds, and `Scripts/check-release-config.sh`.

### macOS 14+

Open the checked-in Xcode project:

```sh
open Apps/macOS/SystemInsights.xcodeproj
```

The Xcode project links **NeedleTailLogger** from GitHub (`3.1.4+`) via a thin
`Apps/macOS/SystemInsightCoreSPM` wrapper (not a vendored copy). After adding Swift files under
`Sources/SystemInsightCore/`, refresh symlinks:

```sh
./Scripts/sync-macos-core-symlinks.sh
```

Select the `SystemInsights` scheme and **My Mac**, then Run to test the menu-bar app.
To render the widget immediately, select the `SystemInsightsWidgetExtension` scheme and Run;
Xcode opens it in WidgetKit Simulator as a medium widget. To put it on the desktop, run the
app once, open **Edit Widgets** on the desktop, search for **System Insights**, and add it.
WidgetKit does not place a widget automatically when its host app launches.

The menu-bar host intentionally uses hardened runtime without App Sandbox because its
host-wide security checks execute read-only system probes. The WidgetKit extension remains
sandboxed and reads only its App Group snapshot cache. Its gallery preview uses sample layout
data; a placed widget shows no snapshot rather than inventing readings until the host app has
written a shared cache.

When Debug runs with Xcode's `Sign to Run Locally` identity, macOS may log
`com.apple.linkd.autoShortcut`/`Error registering app with intents framework` messages. The
static widget does not expose App Intents and does not rely on that registration. To remove
the warnings, configure manual signing: copy
`Apps/macOS/Configuration/Signing.local.xcconfig.example` to `Signing.local.xcconfig`, set your
Team ID, then pick provisioning profiles in **Signing & Capabilities** for both
`SystemInsightsApp` and `SystemInsightsWidgetExtension`. See
[Apps/macOS/Configuration/SIGNING.md](Apps/macOS/Configuration/SIGNING.md).

For macOS cache sharing, signed builds use a team-prefixed App Group identifier
(`$(DEVELOPMENT_TEAM).com.needletails.SystemInsights.shared` from `Signing.local.xcconfig`).
Apple supports this macOS-only identifier form without separately provisioning a `group.`
container. Replace the bundle identifiers and group suffix when adapting the project for another
product. Generate Sparkle EdDSA
keys, provide an HTTPS appcast URL and the public key through `SPARKLE_FEED_URL` and
`SPARKLE_PUBLIC_ED_KEY`, then run the app, enable **Launch at Login**, and add the widget from
the macOS widget gallery.

### Adwaita dashboard (macOS and Ubuntu)

`Apps/ubuntu/SystemInsightsAdwaita` is the shared Swift/Libadwaita UI for both platforms. CI
builds it on macOS and Ubuntu (amd64/arm64). On macOS, install Libadwaita through Homebrew:

```sh
brew install libadwaita pkgconf
swift run system-insights collect --mock
swift build --package-path Apps/ubuntu/SystemInsightsAdwaita --product system-insights-ui
Apps/ubuntu/SystemInsightsAdwaita/.build/debug/system-insights-ui
```

Alternatively, open `Apps/ubuntu/SystemInsightsAdwaita/Package.swift` in Xcode and run the
`SystemInsightsAdwaita` scheme on **My Mac**. On macOS, this dashboard reads the snapshot
from `~/Library/Application Support/SystemInsights/latest.snapshot` (decrypted in-process).

Open the app package above, not `Vendor/adwaita-swift/Package.swift`, which is only its
patched dependency source. If Xcode indexed the package before Libadwaita was installed
and still reports `'adwaita.h' file not found`, use **Product > Clean Build Folder** and
build `SystemInsightsAdwaita` again.

The package consumes the specified Adwaita for Swift upstream revision through
`Vendor/adwaita-swift`. That copy carries a small Swift 6.3 compatibility patch for GLib
typed constants; details are recorded in `Vendor/adwaita-swift/SYSTEM_INSIGHTS_PATCHES.md`.

#### GNOME Builder / Flatpak

Do **not** build with `Vendor/adwaita-swift/io.github.AparokshaUI.Demo.json` — that manifest
builds the upstream Adwaita demo (`Demo`) and fails at install time with
`cannot stat '.build/debug/Demo'`.

Use the project manifest instead:

```sh
# From the repository root
flatpak-builder --force-clean flatpak-build com.needletails.systeminsights.json
```

In GNOME Builder, open **Project Settings → Build → Flatpak manifest** and select
`com.needletails.systeminsights.json` at the repository root (or
`build-aux/flatpak/com.needletails.systeminsights.json`). The build produces
`system-insights-ui`, not `Demo`.

The Flatpak manifest grants host read access (`host-os`), runs host commands via
`flatpak-spawn --host`, and persists `~/.local/share/system-insights` so the app
can collect system metrics and cache snapshots like the native Ubuntu build.

### Ubuntu (GNOME and other desktops)

The same Swift 6 native Libadwaita dashboard runs on Ubuntu. It refreshes live transfer
rates and visible TCP/UDP sockets every 2 seconds while open, refreshes broader telemetry
every 10 seconds, repeats full policy checks every 10 minutes, and displays live interface
speed with a rolling window, port-derived service hints, an exposure watch, and the bounded
activity journal shared through the versioned snapshot. An optional GNOME Shell panel
indicator (`system-insights panel` via Swift) complements the launcher app.

To build from this repository, first install the Libadwaita development dependencies:

```sh
sudo apt install libadwaita-1-dev libgtk-4-dev pkg-config
./Scripts/install-ubuntu.sh
```

The release archive ships prebuilt `system-insights` and `system-insights-ui` executables;
on a standard Ubuntu GNOME desktop it only needs the installed Libadwaita runtime. Launch
the dashboard from the application launcher or with:

```sh
./Scripts/install-ubuntu.sh --install-deps
system-insights-ui
```

Enable the optional top-bar indicator (thin GJS shell; labels from Swift):

```sh
gnome-extensions enable system-insights@needletails.com
```

The Adwaita dashboard matches the macOS password flow: optional protection on first launch,
unlock on each start, and **Cache Security** actions to change or lock the cache. After you
quit or lock, unlock again or set `SYSTEM_INSIGHTS_CACHE_PASSWORD` for scheduled `collect`.

The timer performs an initial collection and then refreshes every 10 minutes without root,
including sockets visible at collection time. The open dashboard journals observed socket
changes more frequently. Cached process/endpoint telemetry is owner-readable only and scheduled
collection does not copy its contents into the user journal. Some failed login records or owning process names may remain unavailable
unless the current account already has suitable visibility.

Remove locally installed components with:

```sh
./Scripts/uninstall-ubuntu.sh
```

## Releases

`CI` tests the Swift package on macOS, Ubuntu AMD64, and Ubuntu ARM64, builds the macOS app
and widget, and builds the Adwaita dashboard on both Linux architectures. Publishing a
GitHub Release with a tag such as `v0.1.0` runs `Release`:

- Ubuntu publishes native `system-insights-ubuntu-amd64-vVERSION.tar.gz` and
  `system-insights-ubuntu-arm64-vVERSION.tar.gz` archives containing the release CLI,
  native Adwaita app, optional panel extension, schema, and installer.
- macOS builds Apple Silicon only, Developer ID signs, notarizes, staples, publishes
  `system-insights-macos-arm64-vVERSION.zip`, and creates Sparkle's signed `appcast.xml`;
  it is not configured for Mac App Store distribution.
- Each executable archive includes a SHA-256 checksum and receives a GitHub artifact
  attestation so downloads hosted on your website can be verified against GitHub provenance.

Sparkle complements rather than replaces Developer ID distribution: each update is still
notarized and Apple-signed, while Sparkle verifies its EdDSA signature and installs it from
the appcast. The Xcode project is locked to Sparkle `2.9.2`.

**Publishing releases** (Developer ID certificates, notarization, GitHub Actions secrets, and
Sparkle keys) is handled by project maintainers, not as part of this open-source tree. Tagged
downloads appear on [GitHub Releases](https://github.com/needletails/SystemInsights/releases).
The public CI workflow runs `Scripts/check-release-config.sh` so placeholder update settings
cannot ship by accident.

**Building from source** on macOS uses manual signing — see
[Apps/macOS/Configuration/SIGNING.md](Apps/macOS/Configuration/SIGNING.md).

Set `SYSTEM_INSIGHTS_DISABLE_LATENCY_PROBE=1` to disable the optional outbound HTTPS
latency sample used for interface health.

Local cache files (`latest.snapshot`, `.snapshot-key`) are gitignored and must not be committed.

Sparkle setup follows its official [documentation](https://sparkle-project.org/documentation/)
and [sandboxing guidance](https://sparkle-project.org/documentation/sandboxing/).
Adwaita dashboard setup follows the
[Adwaita for Swift repository](https://git.aparoksha.dev/aparoksha/adwaita-swift).
