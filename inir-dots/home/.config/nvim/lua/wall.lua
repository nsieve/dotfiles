-- ============================================================================
-- "wall": a solid colour scheme made from the current wallpaper.
--
-- iNiR writes the wallpaper's colours to ~/.local/state/quickshell/user/generated
-- (palette.json + terminal.json, the same files kitty and the bar use).
-- The background and UI come from palette.json; code is coloured with the six
-- terminal colours (red, green, yellow, blue, purple, cyan), so every kind of
-- word gets its own clearly different hue. When you change the wallpaper,
-- every open Neovim recolours itself a moment later.
--
-- Loaded by colors/wall.lua, so `:colorscheme wall` works like any other scheme.
-- ============================================================================
local M = {}

M.dir = vim.fn.expand("~/.local/state/quickshell/user/generated")

-- Used when the files are missing (the colours of the current wallpaper).
local fallback = {
  palette = {
    primary = "#49afc8",
    error = "#f49287",
    success = "#6fc884",
    outline = "#75858a",
    outline_variant = "#3f5156",
    on_surface_variant = "#94a5aa",
    surface_container_lowest = "#081215",
    surface_container_low = "#0f1d21",
    surface_container = "#152428",
    surface_container_high = "#1d2d31",
    surface_container_highest = "#25363b",
  },
  terminal = {
    term0 = "#171F22",
    term1 = "#FFA1B1",
    term2 = "#79CD96",
    term3 = "#CABE52",
    term4 = "#6FC5F5",
    term5 = "#D3ABFC",
    term6 = "#55CCD5",
    term15 = "#D7DCDE",
  },
}

local function read_json(name)
  local ok, lines = pcall(vim.fn.readfile, M.dir .. "/" .. name)
  if not ok or #lines == 0 then
    return nil
  end
  local ok2, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (ok2 and type(data) == "table") and data or nil
end

-- mix("#ff0000", "#0000ff", 0.25) = 25% red + 75% blue
local function mix(a, b, amount)
  local out = "#"
  for i = 2, 6, 2 do
    local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
    out = out .. string.format("%02x", math.floor(x * amount + y * (1 - amount) + 0.5))
  end
  return out
end

local function colors()
  local p, t = read_json("palette.json"), read_json("terminal.json")
  if not p or not t then
    -- Files missing or half-written: keep whatever we had.
    p, t = M.last_p or fallback.palette, M.last_t or fallback.terminal
  end
  p = vim.tbl_extend("keep", p, fallback.palette)
  t = vim.tbl_extend("keep", t, fallback.terminal)
  M.last_p, M.last_t = p, t

  local bg = p.surface_container_low
  -- kitty draws cells that use its own default background (term0) see-through,
  -- so the editor background has to be a different shade to stay solid.
  if bg:lower() == t.term0:lower() then
    bg = p.surface_container_lowest
  end

  return {
    bg = bg,
    bg_dark = p.surface_container_lowest,
    bg_line = p.surface_container, -- current line, floating windows
    bg_menu = p.surface_container_high, -- completion menu, status line
    bg_high = p.surface_container_highest,
    fg = t.term15,
    fg_dim = p.on_surface_variant,
    comment = p.outline,
    line_nr = mix(p.outline, p.outline_variant, 0.5),
    border = p.outline_variant,
    accent = p.primary,

    red = t.term1,
    green = t.term2,
    yellow = t.term3,
    blue = t.term4,
    purple = t.term5,
    cyan = t.term6,
    orange = mix(t.term1, t.term3, 0.5),

    error = p.error,
    ok = p.success,
    terminal = t, -- for programs run inside :terminal
  }
end

function M.load()
  local c = colors()
  vim.cmd("highlight clear")
  vim.o.background = "dark"
  vim.g.colors_name = "wall"

  local tint = function(color, amount)
    return mix(color, c.bg, amount)
  end

  local groups = {
    -- Editor --------------------------------------------------------------
    Normal = { fg = c.fg, bg = c.bg },
    NormalNC = { link = "Normal" },
    NormalFloat = { fg = c.fg, bg = c.bg_line },
    FloatBorder = { fg = c.border, bg = c.bg_line },
    FloatTitle = { fg = c.accent, bg = c.bg_line, bold = true },
    Cursor = { fg = c.bg, bg = c.fg },
    CursorLine = { bg = c.bg_line },
    CursorColumn = { bg = c.bg_line },
    ColorColumn = { bg = c.bg_line },
    LineNr = { fg = c.line_nr },
    CursorLineNr = { fg = c.accent, bold = true },
    SignColumn = { bg = c.bg },
    FoldColumn = { fg = c.line_nr },
    Folded = { fg = c.comment, bg = c.bg_line },
    NonText = { fg = c.border },
    Whitespace = { fg = c.border },
    EndOfBuffer = { fg = c.border },
    Conceal = { fg = c.comment },
    Visual = { bg = tint(c.accent, 0.3) },
    VisualNC = { link = "Visual" },
    Search = { fg = c.fg, bg = tint(c.yellow, 0.3) },
    CurSearch = { fg = c.bg, bg = c.yellow, bold = true },
    IncSearch = { link = "CurSearch" },
    Substitute = { fg = c.bg, bg = c.red },
    MatchParen = { fg = c.accent, bg = c.bg_high, bold = true },
    WinSeparator = { fg = c.border },
    Directory = { fg = c.blue, bold = true },
    Title = { fg = c.blue, bold = true },
    QuickFixLine = { bg = tint(c.accent, 0.2) },

    StatusLine = { fg = c.fg, bg = c.bg_menu },
    StatusLineNC = { fg = c.comment, bg = c.bg_line },
    StatusLineTerm = { link = "StatusLine" },
    StatusLineTermNC = { link = "StatusLineNC" },
    WinBar = { fg = c.fg_dim, bold = true },
    WinBarNC = { fg = c.comment },
    TabLine = { fg = c.comment, bg = c.bg_line },
    TabLineFill = { bg = c.bg_dark },
    TabLineSel = { fg = c.fg, bg = c.bg, bold = true },

    -- Messages at the bottom ("-- INSERT --", errors, prompts)
    ModeMsg = { fg = c.green, bold = true },
    MsgArea = { fg = c.fg },
    MoreMsg = { fg = c.green },
    Question = { fg = c.blue },
    OkMsg = { fg = c.ok },
    ErrorMsg = { fg = c.error, bold = true },
    WarningMsg = { fg = c.yellow },

    -- Completion menu
    Pmenu = { fg = c.fg, bg = c.bg_menu },
    PmenuSel = { bg = mix(c.accent, c.bg_menu, 0.35), bold = true },
    PmenuMatch = { fg = c.accent, bold = true },
    PmenuMatchSel = { fg = c.fg, bold = true },
    PmenuKind = { fg = c.purple },
    PmenuKindSel = { fg = c.purple, bg = mix(c.accent, c.bg_menu, 0.35) },
    PmenuExtra = { fg = c.comment },
    PmenuExtraSel = { fg = c.comment, bg = mix(c.accent, c.bg_menu, 0.35) },
    PmenuSbar = { bg = c.bg_menu },
    PmenuThumb = { bg = c.border },
    ComplMatchIns = {},
    WildMenu = { link = "PmenuSel" },

    -- Code ----------------------------------------------------------------
    Comment = { fg = c.comment, italic = true },
    String = { fg = c.green }, -- "text"
    Character = { fg = c.green }, -- 'a'
    Constant = { fg = c.orange }, -- 42, true, None, NULL
    Identifier = { fg = c.fg }, -- variable names
    Function = { fg = c.blue }, -- printf, my_function
    Statement = { fg = c.purple }, -- if, for, return, def, while
    Operator = { fg = c.cyan }, -- + - = << |=
    PreProc = { fg = c.red }, -- #include, #define, macros like DDRB
    Type = { fg = c.yellow }, -- int, char, struct, str
    Special = { fg = c.cyan }, -- \n, %d, built-in functions
    Delimiter = { fg = c.fg_dim }, -- ( ) [ ] { } , ;
    Underlined = { fg = c.cyan, underline = true },
    Todo = { fg = c.bg, bg = c.yellow, bold = true }, -- TODO, FIXME
    Error = { fg = c.error },

    -- Treesitter: the parts that don't follow the groups above by default.
    ["@variable"] = { fg = c.fg },
    ["@variable.builtin"] = { fg = c.red }, -- self
    ["@constant.builtin"] = { link = "Constant" }, -- True, None, NULL
    ["@type.builtin"] = { link = "Type" }, -- int, void
    ["@module.builtin"] = { link = "Type" },
    ["@markup.raw"] = { fg = c.green }, -- `code` in Markdown
    ["@markup.list"] = { fg = c.cyan },
    ["@markup.quote"] = { fg = c.fg_dim, italic = true },
    ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.heading"] = { link = "Title" },
    ["@markup.link"] = { fg = c.blue },
    ["@markup.link.url"] = { link = "Underlined" },

    -- Errors and warnings from the language server ------------------------
    DiagnosticError = { fg = c.error },
    DiagnosticWarn = { fg = c.yellow },
    DiagnosticInfo = { fg = c.blue },
    DiagnosticHint = { fg = c.cyan },
    DiagnosticOk = { fg = c.ok },
    DiagnosticVirtualTextError = { fg = c.error, bg = tint(c.error, 0.1) },
    DiagnosticVirtualTextWarn = { fg = c.yellow, bg = tint(c.yellow, 0.1) },
    DiagnosticVirtualTextInfo = { fg = c.blue, bg = tint(c.blue, 0.1) },
    DiagnosticVirtualTextHint = { fg = c.cyan, bg = tint(c.cyan, 0.1) },
    DiagnosticVirtualTextOk = { fg = c.ok, bg = tint(c.ok, 0.1) },
    DiagnosticUnderlineError = { undercurl = true, sp = c.error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = c.yellow },
    DiagnosticUnderlineInfo = { undercurl = true, sp = c.blue },
    DiagnosticUnderlineHint = { undercurl = true, sp = c.cyan },
    DiagnosticUnderlineOk = { undercurl = true, sp = c.ok },
    DiagnosticUnnecessary = { fg = c.comment },
    DiagnosticDeprecated = { strikethrough = true, sp = c.error },
    LspReferenceText = { bg = c.bg_high },
    LspReferenceRead = { bg = c.bg_high },
    LspReferenceWrite = { bg = c.bg_high, underline = true },
    LspInlayHint = { fg = c.comment, bg = c.bg_line },
    LspSignatureActiveParameter = { fg = c.accent, bold = true, underline = true },
    SnippetTabstop = { bg = c.bg_high },
    SnippetTabstopActive = { bg = c.bg_high },

    -- Spelling and diffs --------------------------------------------------
    SpellBad = { undercurl = true, sp = c.error },
    SpellCap = { undercurl = true, sp = c.yellow },
    SpellRare = { undercurl = true, sp = c.purple },
    SpellLocal = { undercurl = true, sp = c.cyan },
    Added = { fg = c.green },
    Changed = { fg = c.blue },
    Removed = { fg = c.red },
    DiffAdd = { bg = tint(c.green, 0.2) },
    DiffChange = { bg = tint(c.blue, 0.12) },
    DiffText = { bg = tint(c.blue, 0.3) },
    DiffDelete = { fg = c.red, bg = tint(c.red, 0.15) },
  }

  for name, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, name, spec)
  end

  -- Programs run inside :terminal get the same 16 colours as kitty.
  for i = 0, 15 do
    vim.g["terminal_color_" .. i] = c.terminal["term" .. i]
  end

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
    timer:start(
      500,
      0,
      vim.schedule_wrap(function()
        if vim.g.colors_name == "wall" then
          vim.cmd.colorscheme("wall")
        end
      end)
    )
  end)
end

return M
