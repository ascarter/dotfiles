-- =============================================================================
-- Autocommands
-- =============================================================================

-- Toggle relative numbers in insert mode
local augroup = vim.api.nvim_create_augroup("NumberToggle", { clear = true })
vim.api.nvim_create_autocmd("InsertEnter", {
  group    = augroup,
  callback = function() vim.wo.relativenumber = false end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
  group    = augroup,
  callback = function() vim.wo.relativenumber = true end,
})

-- Briefly highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.hl.on_yank({ timeout = 200 }) end,
})

-- Open help in a vertical split
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  callback = function()
    vim.cmd("wincmd L")
  end,
})

-- Restore cursor position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Open file picker on startup (no args or directory arg)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)
    if vim.fn.argc() == 0 or vim.fn.isdirectory(arg) == 1 then
      if vim.fn.isdirectory(arg) == 1 then
        vim.cmd.cd(arg)
      end
      vim.schedule(function() require("fzf-lua").files() end)
    end
  end,
})

-- Redirect :edit <directory> to fzf file picker
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    if vim.fn.isdirectory(vim.api.nvim_buf_get_name(args.buf)) == 1 then
      vim.schedule(function()
        vim.cmd("bwipeout " .. args.buf)
        require("fzf-lua").files()
      end)
    end
  end,
})
