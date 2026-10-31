#!/usr/bin/env bash
# sync.sh — copy the live configs listed in paths.txt into ./home  (machine -> repo)
#
# Run this after changing your rice, then review with `git diff` and commit.
# ./home is rebuilt from scratch every time, so it always mirrors paths.txt exactly.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
OUT="$REPO/home"
STAGE="$(mktemp -d "$REPO/.home.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT

# Junk that lives inside tracked dirs but shouldn't be committed.
EXCLUDES=(--exclude=cached_layouts --exclude='*.bak' --exclude='*.lock')

while IFS= read -r line; do
    p="${line%%#*}"; p="${p%"${p##*[![:space:]]}"}"   # strip comments + trailing space
    [[ -z "$p" ]] && continue
    p="${p%/}"
    src="$HOME/$p"
    if [[ ! -e "$src" ]]; then
        echo "  skip (not found): ~/$p"
        continue
    fi
    mkdir -p "$STAGE/$(dirname "$p")"
    if [[ -d "$src" ]]; then
        rsync -a "${EXCLUDES[@]}" "$src/" "$STAGE/$p/"
    else
        cp -a "$src" "$STAGE/$p"
    fi
    echo "  ok  ~/$p"
done < "$REPO/paths.txt"

cfg="$STAGE/.config/inir/config.json"
# iNiR writes config.json in two formats (the shell vs. its jq scripts); normalize so diffs show real changes only.
if [[ -f "$cfg" ]] && command -v jq >/dev/null; then
    jq --indent 4 . "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
fi
# Don't commit the hotspot password (install.sh keeps the target machine's own one).
[[ -f "$cfg" ]] && sed -i '/"hotspot": {/,/}/ s/"password": "[^"]*"/"password": ""/' "$cfg"

rm -rf "$OUT"
mv "$STAGE" "$OUT"
trap - EXIT

# Remember which $HOME these paths were written under (install.sh rewrites it if different).
echo "$HOME" > "$REPO/.source-home"

# Package lists: native repo packages and AUR/foreign packages, explicitly installed.
mkdir -p "$REPO/packages"
pacman -Qqen > "$REPO/packages/native.txt"
pacman -Qqem > "$REPO/packages/aur.txt"
echo "  ok  packages/native.txt ($(wc -l < "$REPO/packages/native.txt")), packages/aur.txt ($(wc -l < "$REPO/packages/aur.txt"))"

echo
git -C "$REPO" status --short -- . 2>/dev/null || true
