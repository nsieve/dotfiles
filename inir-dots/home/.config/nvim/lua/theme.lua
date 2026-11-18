-- ============================================================================
-- Hand-made colour schemes. Each one is a palette (below) painted onto the
-- same list of highlight groups, so they all look and behave alike.
--
--   :colorscheme everforest   soft green-grey, warm (default, set in init.lua)
--   :colorscheme kanagawa     dark ink blue, muted
--   :colorscheme gruvbox      retro, warm brown, high contrast
--   :colorscheme zenbones     almost monochrome: bold and italic instead of colours
--   :colorscheme wall         made from the current wallpaper (follows iNiR)
--
-- Try one with :colorscheme <Tab>. To keep it, change the line in init.lua.
-- To make your own, copy a palette, change the hex codes, and add a file
-- colors/<name>.lua with: require("theme").load("<name>")
-- ============================================================================
local M = {}

-- mix("#ff0000", "#0000ff", 0.25) = 25% red + 75% blue
local function mix(a, b, amount)
  local out = "#"
  for i = 2, 6, 2 do
    local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
    out = out .. string.format("%02x", math.floor(x * amount + y * (1 - amount) + 0.5))
  end
  return out
end

-- PALETTES -------------------------------------------------------------------
-- UI:   bg (editor), bg_dark, bg_line (cursor line, popups), bg_menu (completion
--       menu), bg_high, fg (text), fg_dim, comment, line_nr, border, accent, visual
-- Code: keyword, func, string, type, constant, number, operator, preproc,
--       special, delim (brackets, commas), builtin (self)
-- Plus the plain colours, used for errors, diffs and the :terminal.
-- Optional: styles = { Statement = { bold = true } } adds bold/italic to any group.
M.palettes = {}

-- Everforest (dark, medium) by sainnhe
M.palettes.everforest = {
  bg = "#2d353b", bg_dark = "#232a2e", bg_line = "#343f44", bg_menu = "#3d484d", bg_high = "#475258",
  fg = "#d3c6aa", fg_dim = "#9da9a0", comment = "#859289", line_nr = "#7a8478",
  border = "#4f585e", accent = "#a7c080", visual = "#543a48",
  red = "#e67e80", orange = "#e69875", yellow = "#dbbc7f", green = "#a7c080",
  cyan = "#83c092", blue = "#7fbbb3", purple = "#d699b6", error = "#e67e80", ok = "#a7c080",
  keyword = "#e67e80", func = "#a7c080", string = "#83c092", type = "#dbbc7f",
  constant = "#d699b6", number = "#d699b6", operator = "#e69875", preproc = "#d699b6",
  special = "#dbbc7f", delim = "#9da9a0", builtin = "#d699b6",
}

-- Kanagawa (wave) by rebelot
M.palettes.kanagawa = {
  bg = "#1f1f28", bg_dark = "#16161d", bg_line = "#2a2a37", bg_menu = "#223249", bg_high = "#363646",
  fg = "#dcd7ba", fg_dim = "#c8c093", comment = "#727169", line_nr = "#54546d",
  border = "#54546d", accent = "#7e9cd8", visual = "#2d4f67",
  red = "#e46876", orange = "#ffa066", yellow = "#e6c384", green = "#98bb6c",
  cyan = "#7aa89f", blue = "#7e9cd8", purple = "#957fb8", error = "#e82424", ok = "#98bb6c",
  keyword = "#957fb8", func = "#7e9cd8", string = "#98bb6c", type = "#7aa89f",
  constant = "#ffa066", number = "#d27e99", operator = "#c0a36e", preproc = "#e46876",
  special = "#7fb4ca", delim = "#9cabca", builtin = "#e46876",
}

-- Gruvbox (dark) by morhetz
M.palettes.gruvbox = {
  bg = "#282828", bg_dark = "#1d2021", bg_line = "#32302f", bg_menu = "#3c3836", bg_high = "#504945",
  fg = "#ebdbb2", fg_dim = "#a89984", comment = "#928374", line_nr = "#7c6f64",
  border = "#665c54", accent = "#fabd2f", visual = "#504945",
  red = "#fb4934", orange = "#fe8019", yellow = "#fabd2f", green = "#b8bb26",
  cyan = "#8ec07c", blue = "#83a598", purple = "#d3869b", error = "#fb4934", ok = "#b8bb26",
  keyword = "#fb4934", func = "#b8bb26", string = "#8ec07c", type = "#fabd2f",
  constant = "#d3869b", number = "#d3869b", operator = "#fe8019", preproc = "#83a598",
  special = "#fe8019", delim = "#a89984", builtin = "#83a598",
}

-- Zenbones (dark) by mcchrish: stone background, text told apart by weight and
-- slant more than by colour. Keywords bold, strings and constants italic.
M.palettes.zenbones = {
  bg = "#1c1917", bg_dark = "#171412", bg_line = "#252120", bg_menu = "#2f2a28", bg_high = "#3d3735",
  fg = "#b4bdc3", fg_dim = "#8e8682", comment = "#6e6763", line_nr = "#5b5552",
  border = "#4f4845", accent = "#cfd5d8", visual = "#3d4042",
  red = "#de6e7c", orange = "#b77e64", yellow = "#b77e64", green = "#819b69",
  cyan = "#66a5ad", blue = "#6099c0", purple = "#b279a7", error = "#de6e7c", ok = "#819b69",
  keyword = "#b4bdc3", func = "#b4bdc3", string = "#9da5aa", type = "#9da5aa",
  constant = "#a5aeb4", number = "#a5aeb4", operator = "#8e8682", preproc = "#9da5aa",
  special = "#9da5aa", delim = "#8e8682", builtin = "#b4bdc3",
  styles = {
    Statement = { bold = true }, -- if, for, return
    Function = { bold = true },
    String = { italic = true },
    Character = { italic = true },
    Constant = { italic = true },
    Number = { italic = true },
    ["@variable.builtin"] = { italic = true },
    CurSearch = { fg = "#1c1917", bg = "#b279a7", bold = true }, -- search uses blossom, not yellow
    Search = { fg = "#b4bdc3", bg = "#4d3a48" },
  },
}

-- "wall": made from the wallpaper ---------------------------------------------
-- iNiR writes the wallpaper's colours to ~/.local/state/quickshell/user/generated
-- (palette.json + terminal.json, the same files kitty and the bar use).
M.dir = vim.fn.expand("~/.local/state/quickshell/user/generated")

local wall_fallback = {
  palette = {
    primary = "#49afc8", error = "#f49287", success = "#6fc884", outline = "#75858a",
    outline_variant = "#3f5156", on_surface_variant = "#94a5aa",
    surface_container_lowest = "#081215", surface_container_low = "#0f1d21",
    surface_container = "#152428", surface_container_high = "#1d2d31",
    surface_container_highest = "#25363b",
  },
  terminal = {
    term0 = "#171F22", term1 = "#FFA1B1", term2 = "#79CD96", term3 = "#CABE52",
    term4 = "#6FC5F5", term5 = "#D3ABFC", term6 = "#55CCD5", term15 = "#D7DCDE",
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

local function wall_palette()
  local p, t = read_json("palette.json"), read_json("terminal.json")
  if not p or not t then
    -- Files missing or half-written: keep whatever we had.
    p, t = M.last_p or wall_fallback.palette, M.last_t or wall_fallback.terminal
  end
  p = vim.tbl_extend("keep", p, wall_fallback.palette)
  t = vim.tbl_extend("keep", t, wall_fallback.terminal)
  M.last_p, M.last_t = p, t

  local orange = mix(t.term1, t.term3, 0.5)
  local accent = p.primary
  return {
    bg = p.surface_container_low, bg_dark = p.surface_container_lowest,
    bg_line = p.surface_container, bg_menu = p.surface_container_high,
    bg_high = p.surface_container_highest,
    fg = t.term15, fg_dim = p.on_surface_variant, comment = p.outline,
    line_nr = mix(p.outline, p.outline_variant, 0.5), border = p.outline_variant,
    accent = accent, visual = mix(accent, p.surface_container_low, 0.3),
    red = t.term1, orange = orange, yellow = t.term3, green = t.term2,
    cyan = t.term6, blue = t.term4, purple = t.term5, error = p.error, ok = p.success,
    keyword = t.term5, func = t.term4, string = t.term2, type = t.term3,
    constant = orange, number = orange, operator = t.term6, preproc = t.term1,
    special = t.term6, delim = p.on_surface_variant, builtin = t.term1,
    terminal = t,
  }
end

-- HIGHLIGHT GROUPS -------------------------------------------------------------
function M.load(name)
  local c = name == "wall" and wall_palette() or M.palettes[name]
  vim.cmd("highlight clear")
  vim.o.background = "dark"
  vim.g.colors_name = name

  local tint = function(color, amount)
    return mix(color, c.bg, amount)
  end
  local sel = mix(c.accent, c.bg_menu, 0.35) -- selected item in the completion menu

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
    EndOfBuffer = { fg = c.bg },
    Conceal = { fg = c.comment },
    Visual = { bg = c.visual },
    VisualNC = { link = "Visual" },
    Search = { fg = c.fg, bg = tint(c.yellow, 0.3) },
    CurSearch = { fg = c.bg, bg = c.yellow, bold = true },
    IncSearch = { link = "CurSearch" },
    Substitute = { fg = c.bg, bg = c.red },
    MatchParen = { fg = c.accent, bg = c.bg_high, bold = true },
    WinSeparator = { fg = c.border },
    Directory = { fg = c.blue, bold = true },
    Title = { fg = c.accent, bold = true },
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

    -- Start screen (lua/start.lua)
    StartArt = { fg = c.accent },
    StartTone1 = { fg = mix(c.fg, c.bg, 0.22) }, -- shaded pictures: darkest...
    StartTone2 = { fg = mix(c.fg, c.bg, 0.48) },
    StartTone3 = { fg = mix(c.fg, c.bg, 0.74) },
    StartTone4 = { fg = c.fg }, -- ...lightest
    StartSteam = { fg = c.comment }, -- the coffee picture
    StartMug = { fg = c.fg },
    StartMugShade = { fg = mix(c.fg, c.bg, 0.72) },
    StartCoffee = { fg = mix(c.orange, c.bg_dark, 0.5) },
    StartCrema = { fg = c.orange },
    StartSaucer = { fg = c.line_nr },
    StartKey = { fg = c.orange, bold = true },
    StartText = { fg = c.fg },
    StartFooter = { fg = c.comment, italic = true },

    -- Messages at the bottom ("-- INSERT --", errors, prompts)
    ModeMsg = { fg = c.accent, bold = true },
    MsgArea = { fg = c.fg },
    MoreMsg = { fg = c.green },
    Question = { fg = c.blue },
    OkMsg = { fg = c.ok },
    ErrorMsg = { fg = c.error, bold = true },
    WarningMsg = { fg = c.yellow },

    -- Completion menu
    Pmenu = { fg = c.fg, bg = c.bg_menu },
    PmenuSel = { bg = sel, bold = true },
    PmenuMatch = { fg = c.accent, bold = true },
    PmenuMatchSel = { fg = c.fg, bold = true },
    PmenuKind = { fg = c.purple },
    PmenuKindSel = { fg = c.purple, bg = sel },
    PmenuExtra = { fg = c.comment },
    PmenuExtraSel = { fg = c.comment, bg = sel },
    PmenuSbar = { bg = c.bg_menu },
    PmenuThumb = { bg = c.border },
    ComplMatchIns = {},
    WildMenu = { link = "PmenuSel" },

    -- Code ----------------------------------------------------------------
    Comment = { fg = c.comment, italic = true },
    String = { fg = c.string }, -- "text"
    Character = { fg = c.string }, -- 'a'
    Constant = { fg = c.constant }, -- true, None, NULL
    Number = { fg = c.number }, -- 42, 0xFF
    Float = { link = "Number" },
    Boolean = { link = "Constant" },
    Identifier = { fg = c.fg }, -- variable names
    Function = { fg = c.func }, -- printf, my_function
    Statement = { fg = c.keyword }, -- if, for, return, def, while
    Operator = { fg = c.operator }, -- + - = << |=
    PreProc = { fg = c.preproc }, -- #include, #define, macros like DDRB
    Type = { fg = c.type }, -- int, char, struct, str
    Special = { fg = c.special }, -- \n, %d, built-in functions
    Delimiter = { fg = c.delim }, -- ( ) [ ] { } , ;
    Underlined = { fg = c.blue, underline = true },
    Todo = { fg = c.bg, bg = c.yellow, bold = true }, -- TODO, FIXME
    Error = { fg = c.error },

    -- Treesitter: the parts that don't follow the groups above by default.
    ["@variable"] = { fg = c.fg },
    ["@variable.builtin"] = { fg = c.builtin }, -- self
    ["@constant.builtin"] = { link = "Constant" }, -- True, None, NULL
    ["@type.builtin"] = { link = "Type" }, -- int, void
    ["@module.builtin"] = { link = "Type" },
    ["@markup.raw"] = { fg = c.string }, -- `code` in Markdown
    ["@markup.list"] = { fg = c.special },
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

  for group, extra in pairs(c.styles or {}) do
    groups[group] = vim.tbl_extend("force", groups[group] or {}, extra)
  end

  for group, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, group, spec)
  end

  -- Programs run inside :terminal get matching colours.
  local t = c.terminal or {
    term0 = c.bg_dark, term1 = c.red, term2 = c.green, term3 = c.yellow,
    term4 = c.blue, term5 = c.purple, term6 = c.cyan, term7 = c.fg_dim,
    term8 = c.comment, term9 = c.red, term10 = c.green, term11 = c.yellow,
    term12 = c.blue, term13 = c.purple, term14 = c.cyan, term15 = c.fg,
  }
  for i = 0, 15 do
    vim.g["terminal_color_" .. i] = t["term" .. i]
  end

  if name == "wall" then
    M.watch()
  end
end

-- Reload "wall" when iNiR regenerates the palette (after a wallpaper change).
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
