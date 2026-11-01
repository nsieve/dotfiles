-- ============================================================================
-- "wall": a solid colour scheme generated from the current wallpaper.
--
-- iNiR writes the wallpaper's colours to ~/.local/state/quickshell/user/generated
-- (palette.json + terminal.json, the same files the terminal and bar use).
-- mini.hues turns a background + foreground pair into a full, balanced colour
-- scheme (syntax, popups, file tree, statusline...). When you change the
-- wallpaper, every open Neovim recolours itself a moment later.
--
-- Loaded by colors/wall.lua, so `:colorscheme wall` works like any other scheme.
-- ============================================================================
local M = {}

-- Tweak the look here, then run :colorscheme wall to see it.
M.opts = {
  -- How colourful the syntax is: "low", "lowmedium", "medium", "mediumhigh", "high".
  saturation = "medium",
  -- Colour of the cursor line number, borders, separators and indent guide.
  -- "bg" follows the wallpaper; or "red", "orange", "yellow", "green", "cyan",
  -- "azure", "blue", "purple".
  accent = "bg",
}

M.dir = vim.fn.expand("~/.local/state/quickshell/user/generated")

local fallback = { bg = "#0f1d21", fg = "#d7dcde" }

local function read_json(name)
  local ok, lines = pcall(vim.fn.readfile, M.dir .. "/" .. name)
  if not ok or #lines == 0 then
    return nil
  end
  local ok2, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (ok2 and type(data) == "table") and data or nil
end

-- Pick the editor background and text colour from the wallpaper palette.
local function base_colors()
  local p, t = read_json("palette.json"), read_json("terminal.json")
  if not p or not t then
    -- Files missing or half-written: keep whatever we had.
    return M.last or fallback
  end
  local bg = p.surface_container_low or fallback.bg
  -- kitty draws cells that use its own default background (term0) see-through,
  -- so the editor background has to be a different shade to stay solid.
  if t.term0 and bg:lower() == t.term0:lower() then
    bg = p.surface_container_lowest or fallback.bg
  end
  M.last = { bg = bg, fg = t.term15 or p.on_background or fallback.fg }
  return M.last
end

function M.load()
  local c = base_colors()
  require("mini.hues").setup({
    background = c.bg,
    foreground = c.fg,
    saturation = M.opts.saturation,
    accent = M.opts.accent,
  })
  vim.g.colors_name = "wall"
  M.watch()
end

-- Reload when iNiR regenerates the palette (after a wallpaper change).
function M.watch()
  if M.watcher then
    return
  end
  local handle, timer = vim.uv.new_fs_event(), vim.uv.new_timer()
  if not handle or not timer then
    return
  end
  M.watcher = handle
  handle:start(M.dir, {}, function(err, fname)
    if err or (fname ~= "palette.json" and fname ~= "terminal.json") then
      return
    end
    -- iNiR writes several files in a row; wait until it is done.
    timer:stop()
    timer:start(500, 0, vim.schedule_wrap(function()
      if vim.g.colors_name == "wall" then
        vim.cmd.colorscheme("wall")
      end
    end))
  end)
end

return M
