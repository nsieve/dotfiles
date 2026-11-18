-- ============================================================================
-- Start screen: shown when Neovim opens without a file (just `nvim`).
-- Pictures are pixel art: every character cell holds two square "pixels"
-- (▀ top, ▄ bottom, █ both). Pick one with M.picture below.
--
-- Keys, only on this screen (everywhere else Neovim is untouched):
--   e  new empty file      o  open a file (type a path, Tab completes)
--   r  recent files        c  this config      q  quit
-- Colours: StartArt (one-colour pictures), StartTone1-4 (shaded pictures, dark\n-- to light), StartKey / StartText / StartFooter, all in lua/theme.lua.
-- ============================================================================
local M = {}

-- Which picture to show: "coffee", "me" or "dog".
M.picture = "coffee"

M.pictures = {}

-- From ~/Downloads/nvim1.jpeg. One colour (StartArt), drawn as is.
M.pictures.dog = { lines = vim.split([[
                                       ▄▄▄▄▄▄▄██████
                                  ▄▄████████████████
                               ▄████████████████████
                              ██████████████████████
                            ▄██▀▀▀▀█████████████████
        █▀█▄          ▄▄▄██████▄    ▀███████████████
          ▀█▄    ▄▄▄█████████████▄▄▄███████████████▀
           ▀██ ▀█▀████████████████▄█████████████████
            ▀█▄    ████████████████████████████████▀
             ▀█▄   ████████████████████████████ ▀▀▄▄
              ▀██   ███████████████████████████▄   ▀
              ▄███  ▀███████████████████████████
           ████████     ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█████████  ▄
        ▄█ ▀███████▄                   ████████▄▄███
       ▄     ▀▀█████▄                ▀██████████████
      ▀▀▀       ▀██▀                 ▄██████████████
                 ▀██▄              ▄█████████████▀▀
                  ███▄             ██████████████
                  ▀███             ▀██████▀  ██
               ██▄█████▄            ▀██████▄▄▀   ▄██
                ▀▀▀▀▀████            ▀▀█████   ▄████
                      ▀███                   ███████
                        ███                  ███████
]], "\n", { trimempty = true }) }

-- Drawn by hand (well, by a small script): a mug of coffee with steam.
-- 1 steam, 2 mug in shadow, 3 mug, 4 coffee, 5 reflection, 6 saucer.
M.pictures.coffee = {
  groups = { "StartSteam", "StartMugShade", "StartMug", "StartCoffee", "StartCrema", "StartSaucer" },
  tones = vim.split([[
000000000000000000000001000000000000000000000
000000000000000000000010000000000000000000000
000000000000000000000010000000000000000000000
000000000000000001000100000000000000000000000
000000000000000001000100010000000000000000000
000000000000000010001000001000000000000000000
000000000000000010001000001000000000000000000
000000000000000100010000000100000000000000000
000000000000001000001000000100000000000000000
000000000000001000001000000010000000000000000
000000000000001000001000000010000000000000000
000000000000010000000100000001000000000000000
000000000000001000000010000010000000000000000
000000000000001000000010000010000000000000000
000000000000000100000001000100000000000000000
000000000000000100000001000100000000000000000
000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000
000000033333333333333333333332222220000000000
000000033455544544554444444444444220000000000
000000033445555444444444444444444220000000000
000000033444444444444444444444444220000000000
000000033333333333333333333332222220000000000
000000033333333333333333333332222220000000000
000000033333333333333333333332222222222220000
000000033333333333333333333332222222222222000
000000033333333333333333333332222220000022000
000000033333333333333333333332222220000022000
000000033333333333333333333332222220000022000
000000033333333333333333333332222220000022000
000000033333333333333333333332222220000022000
000000033333333333333333333332222220000022000
000000033333333333333333333332222220000022000
000000033333333333333333333332222220000022000
000000033333333333333333333332222220000022000
000000033333333333333333333332222220000022000
000000033333333333333333333332222222222222000
000000033333333333333333333332222222222220000
000000033333333333333333333332222220000000000
000000033333333333333333333332222220000000000
000000033333333333333333333332222220000000000
000000033333333333333333333332222220000000000
000000003333333333333333333332222200000000000
000666666666666666666666666666666666666666000
666666666666666666666666666666666666666666666
666666666666666666666666666666666666666666666
000666666666666666666666666666666666666666000
000000000000066666666666666666660000000000000
]], "\n", { trimempty = true }),
}

-- "me" (your portrait) lives in lua/start_me.lua, which is not in the public
-- dotfiles. Without that file the picture simply isn't there.
local ok_me, me = pcall(require, "start_me")
if ok_me then M.pictures.me = me.me end

M.menu = {
  { key = "e", text = "new file", run = function() vim.cmd.enew() end },
  { key = "o", text = "open file", run = function() vim.api.nvim_feedkeys(":edit ", "n", false) end },
  { key = "r", text = "recent files", run = function() M.recent() end },
  { key = "c", text = "config", run = function() vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua") end },
  { key = "q", text = "quit", run = function() vim.cmd.quitall() end },
}

-- Recently opened files that still exist (Neovim remembers them in :oldfiles).
function M.recent()
  local files = {}
  for _, f in ipairs(vim.v.oldfiles) do
    if #files >= 15 then break end
    if vim.fn.filereadable(f) == 1 and not f:match("^/tmp/") and not f:match("/doc/.*%.txt$") then
      table.insert(files, f)
    end
  end
  vim.ui.select(files, {
    prompt = "Recent files",
    format_item = function(f) return vim.fn.fnamemodify(f, ":~") end,
  }, function(choice)
    if choice then vim.cmd.edit(vim.fn.fnameescape(choice)) end
  end)
end

local ns = vim.api.nvim_create_namespace("start")

-- Turns a picture into text lines plus colour spans { line, byte_from, byte_to, group }.
local function render(pic)
  if pic.lines then
    local spans = {}
    for i, l in ipairs(pic.lines) do spans[i] = { { 0, #l, "StartArt" } } end
    return pic.lines, spans
  end
  -- Shaded picture: a cell shows its top pixel with ▀ (text colour) and its
  -- bottom pixel as the cell background, so each cell holds two tones.
  -- Digit n uses pic.groups[n] if the picture names its own colours, else StartTone<n>.
  local group_of = function(n) return pic.groups and pic.groups[n] or ("StartTone" .. n) end
  local color = function(n) return vim.api.nvim_get_hl(0, { name = group_of(n), link = false }).fg end
  local lines, spans = {}, {}
  for y = 1, #pic.tones, 2 do
    local top, bottom = pic.tones[y], pic.tones[y + 1] or ""
    local text, line_spans = "", {}
    for x = 1, #top do
      local t, b = tonumber(top:sub(x, x)), tonumber(bottom:sub(x, x)) or 0
      local char, group
      if t == 0 and b == 0 then
        char = " "
      elseif t == b then
        char, group = "█", group_of(t)
      elseif b == 0 then
        char, group = "▀", group_of(t)
      elseif t == 0 then
        char, group = "▄", group_of(b)
      else
        char, group = "▀", group_of(t) .. "On" .. group_of(b)
        vim.api.nvim_set_hl(0, group, { fg = color(t), bg = color(b) })
      end
      local from = #text
      text = text .. char
      local last = line_spans[#line_spans]
      if group and last and last[3] == group and last[2] == from then
        last[2] = #text -- same colour as the cell before: extend that span
      elseif group then
        table.insert(line_spans, { from, #text, group })
      end
    end
    table.insert(lines, text)
    table.insert(spans, line_spans)
  end
  return lines, spans
end

local function draw(buf, win)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then return end
  local width, height = vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win)
  local art, art_spans = render(M.pictures[M.picture] or M.pictures.dog)
  local art_w = 0
  for _, l in ipairs(art) do art_w = math.max(art_w, vim.fn.strdisplaywidth(l)) end

  local menu_w = 22
  local v = vim.version()
  local footer = string.format("neovim %d.%d.%d", v.major, v.minor, v.patch)
  -- Picture only if it fits (art + gap + menu + gap + footer); otherwise just the menu.
  local show_art = art_w <= width and #art + 2 + #M.menu + 2 + 1 <= height
  local block = (show_art and #art + 2 or 0) + #M.menu + 2

  local lines, marks = {}, {}
  local function add(text, col_w, hl)
    local pad = math.max(0, math.floor((width - col_w) / 2))
    table.insert(lines, string.rep(" ", pad) .. text)
    if hl then table.insert(marks, { #lines - 1, pad, hl }) end
    return pad
  end
  for _ = 1, math.max(0, math.floor((height - block) / 2)) do table.insert(lines, "") end
  if show_art then
    for i, l in ipairs(art) do
      local pad = add(l, art_w)
      for _, s in ipairs(art_spans[i]) do
        table.insert(marks, { #lines - 1, pad + s[1], s[3], s[2] - s[1] })
      end
    end
    table.insert(lines, "")
    table.insert(lines, "")
  end
  local first_item = #lines + 1
  for _, item in ipairs(M.menu) do
    local pad = add(item.key .. "   " .. item.text .. string.rep(" ", menu_w - 4 - #item.text), menu_w)
    table.insert(marks, { #lines - 1, pad, "StartKey", 1 })
    table.insert(marks, { #lines - 1, pad + 4, "StartText", #item.text })
  end
  table.insert(lines, "")
  add(footer, #footer, "StartFooter")

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    local row, col, hl, len = m[1], m[2], m[3], m[4]
    vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
      end_col = len and col + len or #lines[row + 1], hl_group = hl,
    })
  end
  -- Park the cursor on the first key.
  local pad = math.max(0, math.floor((width - menu_w) / 2))
  pcall(vim.api.nvim_win_set_cursor, win, { first_item, pad })
end

function M.open()
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  -- Plain scratch buffer that disappears as soon as something else is opened.
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "start"
  -- Only for this screen: the file you open next gets your normal settings back.
  for opt, val in pairs({ number = false, relativenumber = false, cursorline = false,
                          signcolumn = "no", list = false, wrap = false }) do
    vim.api.nvim_set_option_value(opt, val, { scope = "local", win = win })
  end
  for _, item in ipairs(M.menu) do
    vim.keymap.set("n", item.key, item.run, { buffer = buf, nowait = true, silent = true, desc = item.text })
  end
  draw(buf, win)
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = buf,
    callback = function() draw(buf, vim.fn.bufwinid(buf)) end,
  })
  -- Another colour scheme: redraw so the shaded picture picks up the new tones.
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      if not vim.api.nvim_buf_is_valid(buf) then return true end -- screen gone: drop this autocmd
      draw(buf, vim.fn.bufwinid(buf))
    end,
  })
end

-- Show it only for a bare `nvim`: no files, nothing piped in, empty buffer.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(buf) == "" and not vim.bo[buf].modified
      and vim.api.nvim_buf_line_count(buf) == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "" then
      M.open()
    end
  end,
})

return M
