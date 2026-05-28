#!/bin/sh
# Print Sparkle generate_keys location and steps for GitHub Actions secrets.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

GENERATE_KEYS=""

# Xcode SPM artifact path (after resolving packages for SystemInsights.xcodeproj)
if [ -d "$ROOT_DIR/Apps/macOS/SystemInsights.xcodeproj" ]; then
    GENERATE_KEYS=$(find "$HOME/Library/Developer/Xcode/DerivedData" "$ROOT_DIR/Apps/macOS" \
        -path '*/artifacts/sparkle/Sparkle/bin/generate_keys' -type f 2>/dev/null | head -n 1)
fi

printf '%s\n' 'Sparkle in-app updater — one-time key setup'
printf '%s\n' 'Repository: https://github.com/needletails/SystemInsights'
printf '%s\n' 'Configure GitHub repository secrets before running the Release workflow (maintainer-only).'
printf '\n'

if [ -n "$GENERATE_KEYS" ] && [ -x "$GENERATE_KEYS" ]; then
    printf 'Found: %s\n\n' "$GENERATE_KEYS"
    printf '%s\n' 'Run these commands:'
    printf '  %s\n' "$GENERATE_KEYS"
    printf '  %s -x %s/private-ed-key.txt\n' "$GENERATE_KEYS" "$ROOT_DIR"
    printf '\n'
    printf '%s\n' 'Then add repository secrets:'
    printf '  SPARKLE_PUBLIC_ED_KEY  = public key printed by generate_keys'
    printf '  SPARKLE_ED_PRIVATE_KEY = contents of private-ed-key.txt (do not commit)'
    printf '  SPARKLE_FEED_URL       = https://github.com/needletails/SystemInsights/releases/latest/download/appcast.xml'
    printf '                           (or your HTTPS appcast URL)'
    exit 0
fi

printf '%s\n' 'generate_keys not found yet.'
printf '%s\n' '1. Open Apps/macOS/SystemInsights.xcodeproj in Xcode.'
printf '%s\n' '2. File → Packages → Resolve Package Versions (wait for Sparkle).'
printf '%s\n' '3. Re-run: sh Scripts/setup-sparkle-keys.sh'
printf '\n'
printf '%s\n' 'Or download Sparkle and run bin/generate_keys from:'
printf '  https://sparkle-project.org/documentation/\n'
exit 1
