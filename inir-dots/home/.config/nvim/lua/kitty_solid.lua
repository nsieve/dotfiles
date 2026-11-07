-- ============================================================================
-- Solid window: kitty is see-through (background_opacity in kitty.conf). While
-- Neovim runs, its kitty window turns fully opaque; quitting or suspending
-- (Ctrl-Z) puts the previous opacity back. Uses kitty's remote control socket
-- (allow_remote_control + listen_on in kitty.conf).
-- ============================================================================
local sock, win = vim.env.KITTY_LISTEN_ON, vim.env.KITTY_WINDOW_ID
if not (sock and win and vim.fn.executable("kitten") == 1) then
  return
end

local saved = nil -- opacity before Neovim made the window solid

local function kitten(args)
  local cmd = vim.list_extend({ "kitten", "@", "--to", sock }, args)
  local ok, res = pcall(function()
    return vim.system(cmd, { text = true }):wait(1000)
  end)
  return (ok and res.code == 0) and res or nil
end

local function make_solid()
  local res = kitten({ "ls", "--match", "id:" .. win })
  if not res then
    return
  end
  local ok, data = pcall(vim.json.decode, res.stdout)
  local current = ok and type(data) == "table" and data[1] and data[1].background_opacity
  -- Already solid (e.g. a Neovim inside Neovim's terminal): leave it alone.
  if type(current) == "number" and current < 1 then
    saved = current
    kitten({ "set-background-opacity", "--match", "id:" .. win, "1" })
  end
end

local function restore()
  if saved then
    kitten({ "set-background-opacity", "--match", "id:" .. win, tostring(saved) })
    saved = nil
  end
end

local group = vim.api.nvim_create_augroup("KittySolid", { clear = true })
vim.api.nvim_create_autocmd({ "UIEnter", "VimResume" }, {
  group = group,
  callback = function()
    vim.schedule(make_solid)
  end,
})
vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, { group = group, callback = restore })
