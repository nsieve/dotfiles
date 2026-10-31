// inirGlass: "fake glass" Spotify. A blurred copy of the wallpaper sits behind
// translucent panels; text, buttons and covers stay fully solid.
// The image is written by ~/.config/spicetify/inir-glass/update.sh on every
// wallpaper change (into Spotify's xpui dir, served at /inir-glass/bg.jpg).
// Tweak TINT (0 = clear, 1 = solid theme colour) and RIM to taste.
(function inirGlass() {
  const TINT = 0.40;
  const RIM = 0.10;
  if (!document.head) { setTimeout(inirGlass, 100); return; }

  const css = (stamp) => `
html body .Root__top-container {
  background: #000 url("https://xpui.app.spotify.com/inir-glass/bg.jpg?v=${stamp}") center / cover no-repeat !important;
}
/* Flat "base" fills go clear so the panel glass shows; hovers become light veils. */
html body .Root__top-container, html body .Root__top-container * {
  --background-base: transparent !important;
  --background-highlight: rgba(255, 255, 255, 0.07) !important;
  --background-press: rgba(255, 255, 255, 0.12) !important;
  --background-elevated-base: rgba(255, 255, 255, 0.06) !important;
  --background-elevated-highlight: rgba(255, 255, 255, 0.10) !important;
}
html body .Root__globalNav { background: transparent !important; }
/* The four panels: tinted glass with a light rim. */
html body .Root__nav-bar,
html body .Root__main-view,
html body .Root__right-sidebar,
html body [data-testid="now-playing-bar"] {
  background-color: rgba(var(--spice-rgb-main), ${TINT}) !important;
  border: 1px solid rgba(255, 255, 255, ${RIM}) !important;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.08) !important;
  border-radius: 12px !important;
  overflow: hidden;
}
html body .Root__nav-bar > div, html body .Root__main-view > div, html body .Root__right-sidebar > div,
html body [data-testid="now-playing-bar"] > div, html body .YourLibraryX,
html body .Root__right-sidebar aside, html body .NowPlayingView {
  background: transparent !important;
}
/* Home shortcut tiles: glass instead of solid cards. */
html body .view-homeShortcutsGrid-shortcut { background-color: rgba(255, 255, 255, 0.07) !important; }
html body .view-homeShortcutsGrid-shortcut:hover { background-color: rgba(255, 255, 255, 0.13) !important; }
`;

  let style = document.getElementById("inir-glass");
  if (!style) {
    style = document.createElement("style");
    style.id = "inir-glass";
    document.head.appendChild(style);
  }
  style.textContent = css(Date.now());
  // update.sh calls this through the debug port after writing a new image.
  window.inirGlassRefresh = () => { style.textContent = css(Date.now()); return "refreshed"; };
})();
