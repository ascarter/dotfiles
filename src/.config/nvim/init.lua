local xdg_config_home = os.getenv("XDG_CONFIG_HOME")

-- Add vim config to path
vim.opt.runtimepath:append(xdg_config_home .. "/vim")
vim.cmd('source ' .. xdg_config_home .. '/vim/vimrc')

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- boostrap lazy.nvim, LazyVim, and your plugins
-- require("config.lazy")

-- vim: ts=2 sts=2 sw=2 et
