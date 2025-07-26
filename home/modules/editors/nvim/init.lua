-- Basic settings (equivalent to :set ...)
vim.opt.compatible = false
vim.opt.showmatch = true
vim.opt.ignorecase = true
vim.opt.mouse = "a"
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.autoindent = true
vim.opt.number = true
vim.opt.wildmode = { "longest", "list" }
vim.opt.colorcolumn = "80"
vim.cmd("filetype plugin indent on")
vim.cmd("syntax on")
vim.opt.clipboard = "unnamedplus"
vim.opt.ttyfast = true
vim.opt.swapfile = false
vim.opt.spell = true
vim.opt.spelllang = { "en_us", "nl" }

-- Leader
vim.g.mapleader = ","

-- colorscheme-mappings
vim.keymap.set("n", "<leader>tg", "<cmd>colorscheme gruvbox<CR>")
vim.keymap.set("n", "<leader>tt", "<cmd>colorscheme tokyonight<CR>")
vim.keymap.set("n", "<leader>tc", "<cmd>colorscheme catppuccin<CR>")
vim.keymap.set("n", "<leader>tn", "<cmd>colorscheme nord<CR>")

-- spelling
vim.keymap.set("n", "<leader>se", "<cmd>set spelllang=en_us<CR>")
vim.keymap.set("n", "<leader>sn", "<cmd>set spelllang=nl<CR>")
vim.keymap.set("n", "<leader>ss", "<cmd>set spell!<CR>")

-- Transparent UI colors
vim.cmd [[
  hi NonText ctermbg=none guibg=NONE
  hi Normal guibg=NONE ctermbg=NONE
  hi NormalNC guibg=NONE ctermbg=NONE
  hi SignColumn ctermbg=NONE ctermfg=NONE guibg=NONE
  hi Pmenu ctermbg=NONE ctermfg=NONE guibg=NONE
  hi FloatBorder ctermbg=NONE ctermfg=NONE guibg=NONE
  hi NormalFloat ctermbg=NONE ctermfg=NONE guibg=NONE
  hi TabLine ctermbg=None ctermfg=None guibg=None
]]

-- treesitter
require('nvim-treesitter.configs').setup {
  ensure_installed = {},
  highlight = { enable = true },
}

-- lsp
local lspconfig = require('lspconfig')
lspconfig.pyright.setup {}
lspconfig.texlab.setup {}
lspconfig.nil_ls.setup {}

-- COMPLETION
local cmp = require('cmp')
cmp.setup({
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
    { name = 'spell' },
  },
  mapping = {
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  },
})
