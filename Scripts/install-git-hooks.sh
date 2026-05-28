#!/bin/sh
# Copy repository git hooks into .git/hooks (local only; does not change global git config).
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HOOKS_SRC="$ROOT_DIR/Scripts/git-hooks"
HOOKS_DST="$ROOT_DIR/.git/hooks"

if [ ! -d "$ROOT_DIR/.git" ]; then
    printf '%s\n' 'install-git-hooks: not a git repository — run from the repo root after git init.' >&2
    exit 1
fi

mkdir -p "$HOOKS_DST"
for hook in "$HOOKS_SRC"/*; do
    [ -f "$hook" ] || continue
    name=$(basename "$hook")
    cp "$hook" "$HOOKS_DST/$name"
    chmod +x "$HOOKS_DST/$name"
    printf 'Installed %s\n' "$name"
done

printf '%s\n' 'Git hooks installed. pre-commit will run Scripts/verify-safe-to-commit.sh on each commit.'
