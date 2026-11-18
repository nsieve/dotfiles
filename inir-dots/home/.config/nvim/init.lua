-- ============================================================================
-- Neovim config, kept small on purpose. There are no custom shortcuts: every
-- key does what Neovim's own tutorial and help say it does.
--
--   New to Vim?  Run :Tutor inside Neovim (about 30 minutes).
--   Any option:  :help 'scrolloff'  (with the quotes) explains it.
--
--   init.lua             options, plugins, language servers (this file)
--   lua/theme.lua        colour schemes (everforest, kanagawa, gruvbox, wall)
--   lua/start.lua        start screen (pixel-art dog + menu) for a bare `nvim`
--   lua/kitty_solid.lua  makes the kitty window solid, Neovim-coloured, while Neovim runs
-- ============================================================================

-- OPTIONS --------------------------------------------------------------------
vim.o.number = true -- line numbers...
vim.o.relativenumber = true -- ...counted from the cursor line (handy for 5j, d3k)
vim.o.cursorline = true -- highlight the line the cursor is on
vim.o.scrolloff = 8 -- keep 8 lines visible above and below the cursor
vim.o.signcolumn = "yes" -- always leave room for error signs, so text doesn't shift
vim.o.ignorecase = true -- searches ignore upper/lower case...
vim.o.smartcase = true -- ...unless you type a capital letter
vim.o.expandtab = true -- the Tab key inserts spaces
vim.o.shiftwidth = 2 -- indent by 2 spaces (Python uses its own 4)
vim.o.tabstop = 2
vim.o.clipboard = "unnamedplus" -- y and p use the system clipboard (Ctrl-C/Ctrl-V elsewhere)
vim.o.undofile = true -- undo history is kept after closing a file
vim.o.swapfile = false -- no .swp files, no "ATTENTION" warnings
vim.o.winborder = "rounded" -- border around popups
vim.o.title = true -- name the kitty window "nvim: file". niri sees the name and makes
vim.o.titlestring = "nvim: %t" -- the window square (rule in niri's 90-user-extra.kdl)
vim.o.laststatus = 0 -- no status line (Ctrl-g shows the file name and if it's saved)
vim.opt.fillchars = { eob = " " } -- no ~ on the empty lines after the end of the file

-- PLUGINS (vim.pack, built into Neovim) --------------------------------------
-- None of these add shortcuts; they work in the background.
vim.pack.add({
  "https://github.com/nvim-treesitter/nvim-treesitter", -- better syntax colours
  "https://www.github.com/neovim/nvim-lspconfig", -- settings for each language server
  "https://github.com/mason-org/mason.nvim", -- :Mason installs/updates language servers
})

-- Colour scheme: the current look picks it (`rice <look>` writes the name to
-- ~/.config/rice/nvim-colorscheme). Without a look it's everforest.
-- Others: kanagawa, gruvbox, zenbones, wall (try :colorscheme <Tab>).
local ok, scheme = pcall(vim.fn.readfile, vim.fn.expand("~/.config/rice/nvim-colorscheme"))
if not (ok and scheme[1] and pcall(vim.cmd.colorscheme, scheme[1])) then
  vim.cmd.colorscheme("everforest")
end
require("kitty_solid")
require("start") -- start screen when Neovim opens without a file

-- Flash the text you just copied with y.
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank()
  end,
})

-- SYNTAX COLOURS (Treesitter) ------------------------------------------------
-- Parsers are downloaded once; :TSUpdate updates them.
require("nvim-treesitter").install({
  "c", "cpp", "python", "vhdl", "lua", "bash", "fish", "make",
  "markdown", "markdown_inline", "json", "toml", "yaml", "vim", "vimdoc",
})
vim.treesitter.language.register("cpp", "arduino") -- .ino files are C++
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf) -- quietly skip languages without a parser
  end,
})

-- LANGUAGE SERVERS (errors, completion, go to definition) ---------------------
-- clangd: C/C++   basedpyright + ruff: Python   lua_ls: Lua   vhdl_ls: VHDL
--
-- Built-in keys once a server is running (all Neovim defaults):
--   K          docs for the word under the cursor
--   Ctrl-]     go to definition       Ctrl-o  jump back
--   grn        rename                 grr     list references
--   gra        quick fixes            Ctrl-w d  show the error on this line
--   ]d  [d     next / previous error
--   Insert mode: Ctrl-n / Ctrl-p pick a suggestion, Ctrl-y accepts it,
--                Ctrl-e closes the menu, Ctrl-s shows a function's parameters
require("mason").setup()

vim.lsp.config("basedpyright", {
  settings = { basedpyright = { analysis = { typeCheckingMode = "standard" } } },
})
vim.lsp.config("clangd", { cmd = { "clangd", "--header-insertion=never" } })
vim.lsp.config("lua_ls", {
  settings = { Lua = { workspace = { library = { vim.env.VIMRUNTIME } } } },
})
vim.lsp.enable({ "clangd", "basedpyright", "ruff", "lua_ls", "vhdl_ls" })

vim.diagnostic.config({
  virtual_text = true, -- show the error message at the end of the line
  severity_sort = true, -- errors win over warnings
})

-- Show suggestions while typing (Neovim's own completion menu).
vim.o.completeopt = "menuone,noselect,popup"
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client or not client:supports_method("textDocument/completion") then
      return
    end
    -- Ask on every letter, not only after "." or "->".
    local provider = client.server_capabilities.completionProvider
    provider.triggerCharacters = provider.triggerCharacters or {}
    for char in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"):gmatch(".") do
      table.insert(provider.triggerCharacters, char)
    end
    vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
  end,
})
