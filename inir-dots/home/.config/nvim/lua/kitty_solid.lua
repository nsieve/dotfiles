-- ============================================================================
-- Full, solid window: while Neovim runs, its kitty window
--   * turns fully opaque (kitty is normally see-through, background_opacity),
--   * paints kitty's own background in Neovim's background colour, and
--   * swaps kitty's margin for padding of the same size (FRAME). The margin
--     always shows the terminal's colour; padding shows the background, so the
--     frame around the text is Neovim-coloured and the whole window is Neovim.
-- Quitting or suspending (Ctrl-Z) puts everything back. Uses kitty's remote
-- control socket (allow_remote_control + listen_on in kitty.conf).
-- ============================================================================
local sock, win = vim.env.KITTY_LISTEN_ON, vim.env.KITTY_WINDOW_ID
-- vim.env.NVIM is set inside Neovim's own :terminal; leave the window to the outer Neovim.
local M = { refresh = function() end }
if not (sock and win and vim.fn.executable("kitten") == 1) or vim.env.NVIM then
  return M
end

-- Frame around the text, in points (kitty.conf's window_margin_width is 21.75). 0 = no frame.
-- The left side is thinner: the line numbers already leave room there.
local FRAME = 21.75
local FRAME_LEFT = 14.5

local match = { "--match", "id:" .. win }
local saved = nil -- how the window looked before Neovim: { opacity = 0.85, background = "#171f22" }

local function kitten(args)
  local cmd = vim.list_extend({ "kitten", "@", "--to", sock }, args)
  local ok, res = pcall(function()
    return vim.system(cmd, { text = true }):wait(1000)
  end)
  return (ok and res.code == 0) and res or nil
end

-- Neovim's background colour as "#rrggbb", or nil.
local function editor_background()
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  return bg and string.format("#%06x", bg) or nil
end

local function paint_background()
  local bg = editor_background()
  if saved and bg then
    kitten(vim.list_extend({ "set-colors" }, vim.list_extend(vim.deepcopy(match), { "background=" .. bg })))
  end
end

local function take_over()
  if saved then
    return
  end
  saved = {}
  local res = kitten(vim.list_extend({ "ls" }, vim.deepcopy(match)))
  local ok, data = pcall(vim.json.decode, res and res.stdout or "")
  local opacity = ok and type(data) == "table" and data[1] and data[1].background_opacity
  if type(opacity) == "number" and opacity < 1 then
    saved.opacity = opacity
    kitten(vim.list_extend({ "set-background-opacity" }, vim.list_extend(vim.deepcopy(match), { "1" })))
  end
  local colors = kitten(vim.list_extend({ "get-colors" }, vim.deepcopy(match)))
  saved.background = colors and colors.stdout:match("\nbackground%s+(#%x+)") or colors and colors.stdout:match("^background%s+(#%x+)")
  kitten(vim.list_extend({ "set-spacing" }, vim.list_extend(vim.deepcopy(match), { "margin=0", "padding=" .. FRAME, "padding-left=" .. FRAME_LEFT })))
  paint_background()
end

local function give_back()
  if not saved then
    return
  end
  kitten(vim.list_extend({ "set-spacing" }, vim.list_extend(vim.deepcopy(match), { "margin=default", "padding=default" })))
  if saved.relooked then
    -- The look changed while Neovim ran: go back to the new look, not the old one.
    -- (--toggle 1 while at 1 = back to kitty.conf's opacity.)
    kitten(vim.list_extend({ "set-colors" }, vim.list_extend(vim.deepcopy(match), { vim.fn.expand("~/.config/kitty/current-theme.conf") })))
    kitten(vim.list_extend({ "set-background-opacity", "--toggle" }, vim.list_extend(vim.deepcopy(match), { "1" })))
  elseif saved.background then
    kitten(vim.list_extend({ "set-colors" }, vim.list_extend(vim.deepcopy(match), { "background=" .. saved.background })))
  end
  if saved.opacity and not saved.relooked then
    kitten(vim.list_extend({ "set-background-opacity" }, vim.list_extend(vim.deepcopy(match), { tostring(saved.opacity) })))
  end
  saved = nil
end

-- Called by `rice` after it switches looks (kitty just reloaded its config,
-- which undoes the solid window): make it solid again.
function M.refresh()
  if not saved then
    return
  end
  saved.relooked = true
  kitten(vim.list_extend({ "set-background-opacity" }, vim.list_extend(vim.deepcopy(match), { "1" })))
  kitten(vim.list_extend({ "set-spacing" }, vim.list_extend(vim.deepcopy(match), { "margin=0", "padding=" .. FRAME, "padding-left=" .. FRAME_LEFT })))
  paint_background()
end

local group = vim.api.nvim_create_augroup("KittySolid", { clear = true })
vim.api.nvim_create_autocmd({ "UIEnter", "VimResume" }, {
  group = group,
  callback = function()
    vim.schedule(take_over)
  end,
})
-- New colours (another colour scheme, or the wallpaper changed): repaint kitty to match.
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = paint_background })
vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, { group = group, callback = give_back })
return M
