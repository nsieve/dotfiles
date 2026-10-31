#!/usr/bin/env bash
# update.sh — make Spotify's "fake glass" background from the current wallpaper.
#
# Writes a blurred copy of the wallpaper to <spotify>/Apps/xpui/inir-glass/bg.jpg,
# where the inirGlass.js Spicetify extension shows it, then asks a running Spotify
# to reload it through its debug port. Run automatically on every wallpaper change
# by ~/.config/systemd/user/inir-spotify-glass.path; safe to run by hand.
set -euo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/inir/config.json"
PORT=8976          # set by iNiR in ~/.config/spotify-flags.conf
BLUR=22            # how frosted the background is
WIDTH=1600

wall="$(cat "$STATE/wallpaper/path.txt" 2>/dev/null || true)"
[[ -f "$wall" ]] || wall="$(jq -r '.background.wallpaperPath // empty' "$CFG" 2>/dev/null || true)"
[[ -f "$wall" ]] || { echo "inir-glass: no wallpaper found"; exit 0; }

spotify_dir="$(awk -F'= *' '/^spotify_path/{print $2; exit}' "${XDG_CONFIG_HOME:-$HOME/.config}/spicetify/config-xpui.ini" 2>/dev/null | xargs)"
xpui="${spotify_dir:-/opt/spotify}/Apps/xpui"
[[ -d "$xpui" && -w "$xpui" ]] || { echo "inir-glass: $xpui missing or not writable (run spicetify first)"; exit 0; }

out="$xpui/inir-glass"
mkdir -p "$out"
tmp="$(mktemp --suffix=.jpg)"
trap 'rm -f "$tmp"' EXIT

# Video wallpapers: use iNiR's thumbnail, or grab a frame.
src="$wall"
case "${wall,,}" in
    *.mp4|*.webm|*.mkv|*.mov|*.gif)
        thumb="$(jq -r '.background.thumbnailPath // empty' "$CFG" 2>/dev/null || true)"
        if [[ -f "$thumb" ]]; then src="$thumb"
        else src="$tmp.png"; ffmpeg -loglevel error -y -i "$wall" -frames:v 1 "$src"; fi ;;
esac

magick "$src" -resize "${WIDTH}x" -blur "0x$BLUR" -modulate 90,115 -quality 82 "$tmp"
rm -f "$tmp.png"
install -m 644 "$tmp" "$out/bg.jpg"
echo "inir-glass: background from $(basename "$wall")"

# Live refresh if Spotify is open with the debug port (no restart needed).
python3 -I - "$PORT" <<'PY' 2>/dev/null || true
import base64, json, os, socket, sys, urllib.request, urllib.parse
port = int(sys.argv[1])
targets = json.load(urllib.request.urlopen(f"http://127.0.0.1:{port}/json/list", timeout=1))
page = next(t for t in targets if t.get("type") == "page" and "spotify.com" in t.get("url", ""))
u = urllib.parse.urlparse(page["webSocketDebuggerUrl"])
s = socket.create_connection((u.hostname, u.port), timeout=2)
s.sendall((f"GET {u.path} HTTP/1.1\r\nHost: {u.hostname}:{u.port}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
           f"Sec-WebSocket-Key: {base64.b64encode(os.urandom(16)).decode()}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
if b" 101 " not in s.recv(4096): raise SystemExit(1)
p = json.dumps({"id": 1, "method": "Runtime.evaluate", "params": {"expression": "window.inirGlassRefresh && window.inirGlassRefresh()"}}).encode()
m = os.urandom(4)
head = bytes([0x81, 0x80 | len(p)]) if len(p) < 126 else bytes([0x81, 0x80 | 126]) + len(p).to_bytes(2, "big")
s.sendall(head + m + bytes(b ^ m[i % 4] for i, b in enumerate(p)))
s.recv(4096)
print("inir-glass: Spotify refreshed")
PY
