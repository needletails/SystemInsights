#!/bin/sh
# Fail if staged or newly-added files would expose secrets, signing material, or maintainer docs.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"
FAILED=0

fail() {
    printf 'verify-safe-to-commit: %s\n' "$1" >&2
    FAILED=1
}

blocked_path() {
    printf '%s\n' "$1" | grep -E \
        '(^|/)docs/|xcuserdata/|\.xcuserstate$|Signing\.local\.xcconfig$|\.(p12|p8|pem|mobileprovision|provisionprofile)$|private-ed-key|(^|/)\.env$|latest\.snapshot$|\.snapshot-key' \
        >/dev/null
}

check_path_list() {
    label=$1
    paths=$2
    if [ -z "$paths" ]; then
        return 0
    fi
    while IFS= read -r path; do
        [ -n "$path" ] || continue
        if blocked_path "$path"; then
            fail "$label would include blocked path: $path"
        fi
    done <<EOF
$paths
EOF
}

# 1. Files already staged for commit (pre-commit / after git add)
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
if [ -n "$STAGED_FILES" ]; then
    printf '%s\n' 'Checking staged files (git diff --cached)...'
    check_path_list 'Staged commit' "$STAGED_FILES"
    if git diff --cached -- ':!Scripts/verify-safe-to-commit.sh' ':!Scripts/check-release-config.sh' \
        | grep -qE 'DEVELOPMENT_TEAM = [A-Z0-9]{10};'; then
        fail 'Staged diff commits DEVELOPMENT_TEAM in Xcode project settings.'
    fi
fi

# 2. Preview of `git add .` — catches gitignore gaps before everything is staged
printf '%s\n' 'Checking staging preview (git add -n)...'
PREVIEW_ADD=$(git add -n . 2>/dev/null | sed -n 's/^add //p' || true)
check_path_list 'git add . preview' "$PREVIEW_ADD"

# 3. Tracked tree (CI and accidental commits)
if git rev-parse --verify HEAD >/dev/null 2>&1; then
    if git ls-files --error-unmatch Apps/macOS/Configuration/Signing.local.xcconfig >/dev/null 2>&1; then
        fail 'Signing.local.xcconfig is tracked — run: git rm --cached Apps/macOS/Configuration/Signing.local.xcconfig'
    fi
    if git ls-files 'docs/' 2>/dev/null | grep -q .; then
        fail 'docs/ has tracked files — run: git rm -r --cached docs/'
    fi
    if git grep -qE 'DEVELOPMENT_TEAM = [A-Z0-9]{10};' -- '*.pbxproj' 2>/dev/null; then
        fail 'Tracked project.pbxproj commits DEVELOPMENT_TEAM — use Signing.local.xcconfig.'
    fi
fi

PBXPROJ="$ROOT_DIR/Apps/macOS/SystemInsights.xcodeproj/project.pbxproj"
if [ -f "$PBXPROJ" ] && grep -qE 'DEVELOPMENT_TEAM = [A-Z0-9]{10};' "$PBXPROJ"; then
    fail 'project.pbxproj commits DEVELOPMENT_TEAM — use Signing.local.xcconfig instead.'
fi

sh "$ROOT_DIR/Scripts/check-release-config.sh"

if [ "$FAILED" -ne 0 ]; then
    exit 1
fi

printf '%s\n' 'verify-safe-to-commit: OK'
