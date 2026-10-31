# inir-dots

My niri + [iNiR](https://github.com/snowarch/inir) rice on Arch.

The repo holds only **my changes on top of iNiR**: the shell itself and the
wallpaper-generated colors come from iNiR, so they aren't stored here.

## Layout

| Path | What |
|---|---|
| `paths.txt` | List of what gets tracked (relative to `$HOME`) |
| `home/` | Copies of those files, mirroring `$HOME` |
| `packages/native.txt`, `packages/aur.txt` | Explicitly installed packages |
| `sync.sh` | Machine → repo |
| `install.sh` | Repo → machine (backs up whatever it overwrites) |

## Saving changes (this machine)

```bash
cd ~/dotfiles/inir-dots
./sync.sh             # copies live configs into home/ and refreshes package lists
git diff              # review
git add . && git commit -m "rice: ..." && git push
```

To track a new file, add it to `paths.txt` and run `./sync.sh` again.

## Setting up a new machine

```bash
# 1. Install iNiR (it handles niri, quickshell, deps, theming)
git clone https://github.com/snowarch/inir.git ~/inir
cd ~/inir && ./setup install

# 2. Pull my dots on top
git clone https://github.com/nsieve/dotfiles.git ~/dotfiles
cd ~/dotfiles/inir-dots
./install.sh --dry-run          # see what will change
./install.sh                    # or: ./install.sh --packages  (installs my packages too)
systemctl --user restart inir
```

Notes:
- `install.sh` saves overwritten files to `~/.local/state/inir-dots/backup-<date>/`.
- If the username differs, `/home/nico` paths (e.g. the wallpaper path) are rewritten automatically.
- The hotspot password is not committed; the new machine keeps its own.
- Monitor blocks in `90-user-extra.kdl` (`HDMI-A-1`, `eDP-1`) only apply when those outputs exist, so they're harmless elsewhere.
- `--packages` installs everything in the lists. Watch the prompt for hardware-specific stuff (GPU drivers, microcode).
- **Spotify theme (Spicetify):** after `--packages` installs `spicetify-cli`, let it patch Spotify:
  `sudo chmod a+wr /opt/spotify /opt/spotify/Apps -R`, then change wallpaper once (or run
  `~/.config/quickshell/inir/scripts/colors/apply-spicetify-theme.sh`). iNiR handles the rest.
- **Spotify fake glass** (blurred wallpaper behind translucent panels), after the step above:
  ```
  spicetify config extensions inirGlass.js && spicetify apply
  systemctl --user daemon-reload
  systemctl --user enable --now inir-spotify-glass.path inir-spotify-glass.service
  ```
  Tint and rim strength: `TINT` / `RIM` at the top of `~/.config/spicetify/Extensions/inirGlass.js`
  (then `spicetify apply`). Blur: `BLUR` in `~/.config/spicetify/inir-glass/update.sh`.
- Keep iNiR on a similar version on both machines. iNiR migrates older `config.json` files forward, but not backward.

## Where to put niri customizations

`./setup update` keeps the existing niri config. It only makes small targeted
edits (migrations), so changes in `config.d/10-80*.kdl` survive updates.

- **Anything iNiR Settings can change** (keyboard layout, touchpad, gaps,
  shadows, window opacity/blur, keybinds): keep it in the file Settings uses
  (`10`, `20`, `30`, `70`). Settings reads and writes those files directly,
  so overriding the same values in `90` would make Settings show the wrong
  value and its toggles would stop doing anything.
- **Things Settings doesn't manage** (custom outputs/modelines, extra
  environment variables, per-app window rules, named workspaces): put them in
  `90-user-extra.kdl`. It loads last and is never edited by iNiR.

`python3 ~/.config/quickshell/inir/scripts/niri-config.py detect-customizations`
lists which niri files differ from iNiR's defaults.
