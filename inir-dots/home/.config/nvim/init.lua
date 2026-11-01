-- ============================================================================
-- Neovim config
--
--   init.lua         everything except the colour scheme (this file)
--   lua/wall.lua     the "wall" colour scheme, generated from the wallpaper
--   colors/wall.lua  lets `:colorscheme wall` find it
--
-- Press <Space> and wait a moment: a popup lists every shortcut (mini.clue).
-- ============================================================================

-- Leader must be set before any <leader> mapping is created.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ============================================================================
-- OPTIONS
-- ============================================================================
vim.opt.termguicolors = true
vim.opt.number = true -- line number
vim.opt.relativenumber = true -- relative line numbers
vim.opt.cursorline = true -- highlight current line
vim.opt.wrap = false -- do not wrap lines by default
vim.opt.scrolloff = 10 -- keep 10 lines above/below cursor
vim.opt.sidescrolloff = 10 -- keep 10 lines to left/right of cursor

vim.opt.tabstop = 2 -- tabwidth
vim.opt.shiftwidth = 2 -- indent width
vim.opt.softtabstop = 2 -- soft tab stop not tabs on tab/backspace
vim.opt.expandtab = true -- use spaces instead of tabs
vim.opt.smartindent = true -- smart auto-indent
vim.opt.autoindent = true -- copy indent from current line

vim.opt.ignorecase = true -- case insensitive search
vim.opt.smartcase = true -- case sensitive if uppercase in string
vim.opt.hlsearch = true -- highlight search matches
vim.opt.incsearch = true -- show matches as you type

vim.opt.signcolumn = "yes" -- always show a sign column
vim.opt.showmatch = true -- highlights matching brackets
vim.opt.cmdheight = 1 -- single line command line
vim.opt.laststatus = 3 -- one statusline at the bottom, even with splits
vim.opt.completeopt = "menuone,noinsert,noselect" -- completion options
vim.opt.showmode = false -- do not show the mode, instead have it in statusline
vim.opt.pumheight = 10 -- popup menu height
vim.opt.pumblend = 0 -- popup menus are solid, not blended with the text behind
vim.opt.winblend = 0 -- floating windows are solid too
vim.opt.winborder = "rounded" -- rounded border on every popup (hover, diagnostics, ...)
vim.opt.synmaxcol = 300 -- syntax highlighting limit
vim.opt.fillchars = { eob = " " } -- hide "~" on empty lines

local undodir = vim.fn.expand("~/.vim/undodir")
if vim.fn.isdirectory(undodir) == 0 then -- create undodir if nonexistent
  vim.fn.mkdir(undodir, "p")
end

vim.opt.backup = false -- do not create a backup file
vim.opt.writebackup = false -- do not write to a backup file
vim.opt.swapfile = false -- do not create a swapfile
vim.opt.undofile = true -- do create an undo file
vim.opt.undodir = undodir -- set the undo directory
vim.opt.updatetime = 300 -- faster completion
vim.opt.timeoutlen = 500 -- timeout duration
vim.opt.ttimeoutlen = 50 -- key code timeout
vim.opt.autoread = true -- auto-reload changes if outside of neovim
vim.opt.autowrite = false -- do not auto-save

vim.opt.hidden = true -- allow hidden buffers
vim.opt.errorbells = false -- no error sounds
vim.opt.backspace = "indent,eol,start" -- better backspace behaviour
vim.opt.autochdir = false -- do not autochange directories
vim.opt.iskeyword:append("-") -- include - in words
vim.opt.path:append("**") -- include subdirs in search
vim.opt.selection = "inclusive" -- include last char in selection
vim.opt.mouse = "a" -- enable mouse support
vim.opt.clipboard:append("unnamedplus") -- use system clipboard
vim.opt.modifiable = true -- allow buffer modifications

-- Cursor: block in normal/visual, thin bar in insert, underline in replace.
vim.opt.guicursor = table.concat({
  "n-v-c-sm:block",
  "i-ci-ve:ver25",
  "r-cr-o:hor20",
  "a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",
}, ",")

-- Folding: requires treesitter available at runtime; safe fallback if not
vim.opt.foldmethod = "expr" -- use expression for folding
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- use treesitter for folding
vim.opt.foldlevel = 99 -- start with all folds open

vim.opt.splitbelow = true -- horizontal splits go below
vim.opt.splitright = true -- vertical splits go right

vim.opt.wildmenu = true -- tab completion
vim.opt.wildmode = "longest:full,full" -- complete longest common match, full completion list, cycle through with Tab
vim.opt.diffopt:append("linematch:60") -- improve diff display
vim.opt.redrawtime = 10000 -- increase neovim redraw tolerance
vim.opt.maxmempattern = 20000 -- increase max memory

-- ============================================================================
-- PLUGINS (vim.pack)
-- ============================================================================
vim.pack.add({
  "https://www.github.com/echasnovski/mini.nvim",
  "https://www.github.com/ibhagwan/fzf-lua",
  "https://www.github.com/nvim-tree/nvim-tree.lua",
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
  },
  -- Language servers
  "https://www.github.com/neovim/nvim-lspconfig",
  "https://github.com/mason-org/mason.nvim",
  {
    src = "https://github.com/saghen/blink.cmp",
    version = vim.version.range("1.*"),
  },
})

-- ============================================================================
-- COLOURS
-- "wall" follows the wallpaper and is fully solid. Settings: lua/wall.lua.
-- Other built-in schemes to try with :colorscheme are catppuccin, habamax, unokai.
-- ============================================================================
vim.cmd.colorscheme("wall")

-- ============================================================================
-- SOLID WINDOW
-- kitty is see-through (background_opacity in kitty.conf). While Neovim runs,
-- its kitty window turns fully opaque; quitting or suspending (Ctrl-Z) puts the
-- previous opacity back. This uses kitty's remote control socket
-- (allow_remote_control + listen_on in kitty.conf), so only kitty windows opened
-- after that was enabled do it.
-- ============================================================================
do
  local sock, win = vim.env.KITTY_LISTEN_ON, vim.env.KITTY_WINDOW_ID
  if sock and win and vim.fn.executable("kitten") == 1 then
    local saved = nil -- opacity before Neovim made the window solid

    local function kitten(args)
      local cmd = { "kitten", "@", "--to", sock }
      vim.list_extend(cmd, args)
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
  end
end

-- ============================================================================
-- KEYMAPS
-- ============================================================================

-- better movement in wrapped text
vim.keymap.set("n", "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true, silent = true, desc = "Down (wrap-aware)" })
vim.keymap.set("n", "k", function()
  return vim.v.count == 0 and "gk" or "k"
end, { expr = true, silent = true, desc = "Up (wrap-aware)" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>", { desc = "Clear search highlights" })

vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
vim.keymap.set({ "n", "v" }, "<leader>x", '"_d', { desc = "Delete without yanking" })

vim.keymap.set("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bd", function()
  require("mini.bufremove").delete()
end, { desc = "Close buffer (keep window)" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

vim.keymap.set("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split window horizontally" })
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Alt+h/j/k/l moves lines and selections (mini.move, set up below).

vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

vim.keymap.set("n", "<leader>pa", function() -- show file path
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  print("file:", path)
end, { desc = "Copy full file path" })

-- Toggles live under <leader>u
vim.keymap.set("n", "<leader>ud", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
vim.keymap.set("n", "<leader>uf", function()
  vim.g.format_on_save = not vim.g.format_on_save
  vim.notify("Format on save: " .. (vim.g.format_on_save and "on" or "off"))
end, { desc = "Toggle format on save" })
vim.keymap.set("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle line wrap" })

-- ============================================================================
-- AUTOCMDS
-- ============================================================================

local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- Format on save. Python is always formatted (ruff). C/C++ only inside projects
-- that have a .clang-format file, so code written in another style is never
-- rewritten behind your back. Toggle with <leader>uf, format by hand with <leader>cf.
vim.g.format_on_save = true
local format_servers = { ruff = true, clangd = true }

local function should_format(buf)
  local ft = vim.bo[buf].filetype
  if ft == "python" then
    return true
  end
  if ft == "c" or ft == "cpp" then
    return vim.fs.root(buf, { ".clang-format", "_clang-format" }) ~= nil
  end
  return false
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(args)
    if not vim.g.format_on_save or vim.bo[args.buf].buftype ~= "" or not should_format(args.buf) then
      return
    end
    local clients = vim.lsp.get_clients({ bufnr = args.buf, method = "textDocument/formatting" })
    local has_formatter = vim.iter(clients):any(function(c)
      return format_servers[c.name]
    end)
    if has_formatter then
      vim.lsp.buf.format({
        bufnr = args.buf,
        timeout_ms = 2000,
        filter = function(c)
          return format_servers[c.name]
        end,
      })
    end
  end,
})

-- highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.hl.on_yank()
  end,
})

-- return to last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  desc = "Restore last cursor position",
  callback = function()
    if vim.o.diff then -- except in diff mode
      return
    end

    local last_pos = vim.api.nvim_buf_get_mark(0, '"') -- {line, col}
    local last_line = vim.api.nvim_buf_line_count(0)

    local row = last_pos[1]
    if row < 1 or row > last_line then
      return
    end

    pcall(vim.api.nvim_win_set_cursor, 0, last_pos)
  end,
})

-- wrap, linebreak and spellcheck on markdown and text files
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
  end,
})

-- ============================================================================
-- TREESITTER (syntax highlighting and folding)
-- ============================================================================
local setup_treesitter = function()
  local treesitter = require("nvim-treesitter")
  treesitter.setup({})
  local ensure_installed = {
    "c",
    "cpp",
    "python",
    "vhdl",
    "lua",
    "vim",
    "vimdoc",
    "query",
    "markdown",
    "markdown_inline",
    "bash",
    "fish",
    "make",
    "json",
    "toml",
    "yaml",
    "html",
    "css",
    "rust",
    "diff",
    "gitcommit",
  }

  local config = require("nvim-treesitter.config")

  local already_installed = config.get_installed()
  local parsers_to_install = {}

  for _, parser in ipairs(ensure_installed) do
    if not vim.tbl_contains(already_installed, parser) then
      table.insert(parsers_to_install, parser)
    end
  end

  if #parsers_to_install > 0 then
    treesitter.install(parsers_to_install)
  end

  -- Arduino sketches (.ino) are C++ underneath.
  vim.treesitter.language.register("cpp", "arduino")

  local group = vim.api.nvim_create_augroup("TreeSitterConfig", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(args)
      if vim.list_contains(config.get_installed(), vim.treesitter.language.get_lang(args.match)) then
        vim.treesitter.start(args.buf)
      end
    end,
  })
end

setup_treesitter()

-- ============================================================================
-- MINI.NVIM MODULES
-- ============================================================================
require("mini.ai").setup({})
require("mini.comment").setup({})
require("mini.move").setup({})
require("mini.surround").setup({})
require("mini.cursorword").setup({})
require("mini.indentscope").setup({})
require("mini.pairs").setup({})
require("mini.trailspace").setup({})
require("mini.bufremove").setup({})
require("mini.notify").setup({})
require("mini.icons").setup({})
require("mini.icons").mock_nvim_web_devicons() -- file icons in nvim-tree and other plugins

-- Statusline: mode | git branch, changes, diagnostics, LSP | file ... file info | line:column
local statusline = require("mini.statusline")
statusline.setup({
  content = {
    active = function()
      local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
      local git = statusline.section_git({ trunc_width = 40 })
      local diff = statusline.section_diff({ trunc_width = 75 })
      local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
      local lsp = statusline.section_lsp({ trunc_width = 75 })
      local filename = statusline.section_filename({ trunc_width = 140 })
      local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })
      local search = statusline.section_searchcount({ trunc_width = 75 })
      return statusline.combine_groups({
        { hl = mode_hl, strings = { mode } },
        { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
        "%<", -- truncate from here when the window is narrow
        { hl = "MiniStatuslineFilename", strings = { filename } },
        "%=", -- everything after this goes to the right
        { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
        { hl = mode_hl, strings = { search, "%l:%v" } },
      })
    end,
  },
})

-- Git: change markers in the sign column + blame
require("mini.diff").setup({
  view = {
    style = "sign",
    signs = { add = "▎", change = "▎", delete = "▎" },
  },
})

require("mini.git").setup({})

local MiniDiff = require("mini.diff")
vim.keymap.set("n", "]h", function()
  MiniDiff.goto_hunk("next")
end, { desc = "Next git hunk" })
vim.keymap.set("n", "[h", function()
  MiniDiff.goto_hunk("prev")
end, { desc = "Prev git hunk" })
vim.keymap.set("n", "<leader>hs", MiniDiff.operator, { desc = "Stage hunk" })
vim.keymap.set("n", "<leader>hp", function()
  MiniDiff.toggle_overlay()
end, { desc = "Preview diff overlay" })
vim.keymap.set("n", "<leader>hb", function()
  require("mini.git").show_at_cursor()
end, { desc = "Git blame/show" })

-- Shortcut hints: press <Space> (or g, z, [, ], ", ', `, Ctrl-w) and wait.
local miniclue = require("mini.clue")
miniclue.setup({
  triggers = {
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },
    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },
    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
    { mode = "n", keys = "'" },
    { mode = "n", keys = "`" },
    { mode = "x", keys = "'" },
    { mode = "x", keys = "`" },
    { mode = "n", keys = '"' },
    { mode = "x", keys = '"' },
    { mode = "i", keys = "<C-r>" },
    { mode = "c", keys = "<C-r>" },
    { mode = "n", keys = "<C-w>" },
  },
  clues = {
    { mode = "n", keys = "<Leader>b", desc = "+Buffers" },
    { mode = "n", keys = "<Leader>c", desc = "+Code" },
    { mode = "n", keys = "<Leader>f", desc = "+Find" },
    { mode = "n", keys = "<Leader>g", desc = "+Go to" },
    { mode = "n", keys = "<Leader>h", desc = "+Git hunks" },
    { mode = "n", keys = "<Leader>n", desc = "+Next" },
    { mode = "n", keys = "<Leader>p", desc = "+Prev / path" },
    { mode = "n", keys = "<Leader>s", desc = "+Splits" },
    { mode = "n", keys = "<Leader>u", desc = "+Toggles" },
    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
    miniclue.gen_clues.square_brackets(),
  },
  window = { delay = 300 },
})

-- ============================================================================
-- FILE TREE AND FUZZY FINDER
-- ============================================================================
require("nvim-tree").setup({
  view = {
    width = 35,
  },
  filters = {
    dotfiles = false,
  },
  renderer = {
    group_empty = true,
  },
})
vim.keymap.set("n", "<leader>e", function()
  require("nvim-tree.api").tree.toggle()
end, { desc = "Toggle file tree" })

-- Needs the `fzf` program (pacman -S fzf).
require("fzf-lua").setup({
  fzf_colors = true, -- take fzf's colours from the colour scheme
})

vim.keymap.set("n", "<leader>ff", function()
  require("fzf-lua").files()
end, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", function()
  require("fzf-lua").live_grep()
end, { desc = "Find text (grep)" })
vim.keymap.set("n", "<leader>fb", function()
  require("fzf-lua").buffers()
end, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", function()
  require("fzf-lua").help_tags()
end, { desc = "Find help" })
vim.keymap.set("n", "<leader>fx", function()
  require("fzf-lua").diagnostics_document()
end, { desc = "Diagnostics (this file)" })
vim.keymap.set("n", "<leader>fX", function()
  require("fzf-lua").diagnostics_workspace()
end, { desc = "Diagnostics (project)" })

-- ============================================================================
-- LSP, DIAGNOSTICS & COMPLETION
-- Language servers are installed with Mason (:Mason to browse/update):
--   clangd (C, C++), basedpyright + ruff (Python), lua_ls (Lua), vhdl_ls (VHDL)
-- ============================================================================
require("mason").setup({})

local diagnostic_signs = {
  Error = "\u{f057} ",
  Warn = "\u{f071} ",
  Hint = "\u{ea61}",
  Info = "\u{f05a}",
}

vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 4 },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
      [vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
      [vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
      [vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    source = true,
    header = "",
    prefix = "",
    focusable = false,
    style = "minimal",
  },
})

local function lsp_on_attach(ev)
  local client = vim.lsp.get_client_by_id(ev.data.client_id)
  if not client then
    return
  end

  -- basedpyright already shows Python docs; ruff's hover would duplicate them.
  if client.name == "ruff" then
    client.server_capabilities.hoverProvider = false
  end

  local bufnr = ev.buf
  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { silent = true, buffer = bufnr, desc = desc })
  end

  map("<leader>gd", function()
    require("fzf-lua").lsp_definitions({ jump_to_single_result = true })
  end, "Definition (picker)")
  map("<leader>gD", vim.lsp.buf.definition, "Definition")
  map("<leader>gS", function()
    vim.cmd("vsplit")
    vim.lsp.buf.definition()
  end, "Definition in split")

  map("<leader>ca", vim.lsp.buf.code_action, "Code action")
  map("<leader>cf", function()
    vim.lsp.buf.format({ timeout_ms = 2000 })
  end, "Format file")
  map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")

  map("<leader>D", function()
    vim.diagnostic.open_float({ scope = "line" })
  end, "Line diagnostics")
  map("<leader>d", function()
    vim.diagnostic.open_float({ scope = "cursor" })
  end, "Diagnostic under cursor")
  map("<leader>nd", function()
    vim.diagnostic.jump({ count = 1 })
  end, "Next diagnostic")
  map("<leader>pd", function()
    vim.diagnostic.jump({ count = -1 })
  end, "Previous diagnostic")

  map("K", vim.lsp.buf.hover, "Hover docs")

  map("<leader>fr", function()
    require("fzf-lua").lsp_references()
  end, "References")
  map("<leader>ft", function()
    require("fzf-lua").lsp_typedefs()
  end, "Type definitions")
  map("<leader>fs", function()
    require("fzf-lua").lsp_document_symbols()
  end, "Symbols (this file)")
  map("<leader>fw", function()
    require("fzf-lua").lsp_workspace_symbols()
  end, "Symbols (project)")
  map("<leader>fi", function()
    require("fzf-lua").lsp_implementations()
  end, "Implementations")

  if client:supports_method("textDocument/codeAction", bufnr) then
    map("<leader>oi", function()
      vim.lsp.buf.code_action({
        context = { only = { "source.organizeImports" }, diagnostics = {} },
        apply = true,
      })
    end, "Organize imports")
  end
end

vim.api.nvim_create_autocmd("LspAttach", { group = augroup, callback = lsp_on_attach })

vim.keymap.set("n", "<leader>q", function()
  vim.diagnostic.setloclist({ open = true })
end, { desc = "Diagnostic list" })

require("blink.cmp").setup({
  keymap = {
    preset = "none",
    ["<C-Space>"] = { "show", "hide" },
    ["<CR>"] = { "accept", "fallback" },
    ["<C-j>"] = { "select_next", "fallback" },
    ["<C-k>"] = { "select_prev", "fallback" },
    ["<Tab>"] = { "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "fallback" },
  },
  appearance = { nerd_font_variant = "mono" },
  completion = {
    menu = {
      auto_show = function()
        return vim.bo.filetype ~= "markdown"
      end,
    },
    -- docs for the selected item appear next to the menu
    documentation = { auto_show = true, auto_show_delay_ms = 300 },
  },
  -- function signature (parameter list) while typing arguments
  signature = { enabled = true },
  sources = { default = { "lsp", "path", "buffer", "snippets" } },
  fuzzy = {
    implementation = "prefer_rust",
    prebuilt_binaries = { download = true },
  },
})

vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

-- C / C++. Per-project compiler flags go in a .clangd file
-- (~/uni/Arduino/.clangd teaches it about the AVR chips).
vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--header-insertion=never" },
})

-- Python: basedpyright for types/completion, ruff for linting + formatting.
vim.lsp.config("basedpyright", {
  settings = {
    basedpyright = {
      disableOrganizeImports = true, -- ruff does this
      analysis = { typeCheckingMode = "standard" },
    },
  },
})
vim.lsp.config("ruff", {})

-- Lua: knows the Neovim API, so editing this config gets completion and docs.
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
      diagnostics = { globals = { "vim" } },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.config("vhdl_ls", {})

vim.lsp.enable({ "clangd", "basedpyright", "ruff", "lua_ls", "vhdl_ls" })

-- ============================================================================
-- FLOATING TERMINAL
-- ============================================================================
vim.api.nvim_create_autocmd("TermClose", {
  group = augroup,
  callback = function()
    if vim.v.event.status == 0 then
      vim.api.nvim_buf_delete(0, {})
    end
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

local terminal_state = { buf = nil, win = nil, is_open = false }

local function FloatingTerminal()
  if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
    vim.api.nvim_win_close(terminal_state.win, false)
    terminal_state.is_open = false
    return
  end

  if not terminal_state.buf or not vim.api.nvim_buf_is_valid(terminal_state.buf) then
    terminal_state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[terminal_state.buf].bufhidden = "hide"
  end

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  terminal_state.win = vim.api.nvim_open_win(terminal_state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  if vim.bo[terminal_state.buf].buftype ~= "terminal" then
    -- same shell as kitty
    local shell = vim.fn.executable("fish") == 1 and "fish" or vim.o.shell
    vim.fn.jobstart({ shell }, { term = true })
  end

  terminal_state.is_open = true
  vim.cmd("startinsert")

  local term_augroup = vim.api.nvim_create_augroup("FloatingTermLeave_" .. terminal_state.win, { clear = true })
  vim.api.nvim_create_autocmd("BufLeave", {
    group = term_augroup,
    buffer = terminal_state.buf,
    callback = function()
      if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
        vim.api.nvim_win_close(terminal_state.win, false)
        terminal_state.is_open = false
      end
    end,
    once = true,
  })
end

vim.keymap.set("n", "<leader>t", FloatingTerminal, { noremap = true, silent = true, desc = "Toggle floating terminal" })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true, desc = "Terminal normal mode" })
vim.keymap.set("t", "<C-q>", function()
  if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
    vim.api.nvim_win_close(terminal_state.win, false)
    terminal_state.is_open = false
  end
end, { noremap = true, silent = true, desc = "Close floating terminal" })
