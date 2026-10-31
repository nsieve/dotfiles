#!/usr/bin/env bash
# install.sh — deploy ./home onto this machine  (repo -> machine)
#
#   ./install.sh              copy configs (backs up anything it overwrites)
#   ./install.sh --dry-run    only show what would change
#   ./install.sh --packages   also install packages/native.txt + packages/aur.txt with yay first
#
# Install iNiR itself BEFORE running this (see README.md).
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
SRC="$REPO/home"
DRY=0 PKGS=0
for a in "$@"; do
    case "$a" in
        -n|--dry-run) DRY=1 ;;
        -p|--packages) PKGS=1 ;;
        -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
        *) echo "unknown option: $a" >&2; exit 1 ;;
    esac
done

[[ -d "$SRC" ]] || { echo "No ./home dir — run sync.sh on the source machine first." >&2; exit 1; }

if [[ ! -d "$HOME/.config/quickshell/inir" ]]; then
    echo "!! iNiR doesn't look installed here (~/.config/quickshell/inir is missing)."
    echo "   Install it first:  git clone https://github.com/snowarch/inir.git ~/inir && cd ~/inir && ./setup install"
    read -rp "   Continue anyway? [y/N] " ans
    [[ "$ans" == [yY]* ]] || exit 1
fi

# ── Packages (opt-in) ───────────────────────────────────────
if (( PKGS )); then
    command -v yay >/dev/null || { echo "yay not found; install it or drop --packages" >&2; exit 1; }
    echo ">> Installing packages (review the prompt — drop hardware-specific ones like drivers)"
    if (( DRY )); then
        echo "   would run: yay -S --needed $(cat "$REPO"/packages/*.txt | wc -l) packages"
    else
        cat "$REPO"/packages/native.txt "$REPO"/packages/aur.txt | yay -S --needed -
    fi
fi

# ── Configs ─────────────────────────────────────────────────
SRC_HOME="$(cat "$REPO/.source-home" 2>/dev/null || echo "$HOME")"
BACKUP="$HOME/.local/state/inir-dots/backup-$(date +%Y%m%d-%H%M%S)"
CFG="$HOME/.config/inir/config.json"

# Keep this machine's own hotspot password (the repo copy has it blanked).
old_pass=""
[[ -f "$CFG" ]] && command -v jq >/dev/null && old_pass="$(jq -r '.hotspot.password // ""' "$CFG" 2>/dev/null || true)"

changed=0
while IFS= read -r -d '' f; do
    rel="${f#"$SRC"/}"
    dest="$HOME/$rel"
    tmp="$(mktemp)"
    cp -a "$f" "$tmp"
    # Rewrite absolute paths from the source machine's $HOME (e.g. wallpaper path).
    if [[ "$SRC_HOME" != "$HOME" ]] && grep -Iq . "$tmp" 2>/dev/null; then
        sed -i "s|$SRC_HOME|$HOME|g" "$tmp"
    fi
    if [[ "$rel" == ".config/inir/config.json" && -n "$old_pass" ]]; then
        esc="$(printf '%s' "$old_pass" | sed 's/[\\&|]/\\&/g')"
        sed -i "/\"hotspot\": {/,/}/ s|\"password\": \"\"|\"password\": \"$esc\"|" "$tmp"
    fi
    if [[ -f "$dest" ]] && cmp -s "$tmp" "$dest"; then
        rm -f "$tmp"; continue
    fi
    changed=$((changed + 1))
    if (( DRY )); then
        [[ -e "$dest" ]] && echo "  update  ~/$rel" || echo "  new     ~/$rel"
        rm -f "$tmp"; continue
    fi
    if [[ -e "$dest" ]]; then
        mkdir -p "$BACKUP/$(dirname "$rel")"
        cp -a "$dest" "$BACKUP/$rel"
    fi
    mkdir -p "$(dirname "$dest")"
    mv "$tmp" "$dest"
    echo "  wrote   ~/$rel"
done < <(find "$SRC" -type f -print0 | sort -z)

if (( DRY )); then
    echo; echo "$changed file(s) would change. Nothing written."
    exit 0
fi

echo
echo "$changed file(s) changed."
[[ -d "$BACKUP" ]] && echo "Backups of overwritten files: $BACKUP"

if command -v niri >/dev/null; then
    echo
    niri validate && echo "niri config OK (niri reloads it automatically)."
fi
echo "Restart the shell to pick up config.json:  systemctl --user restart inir"
