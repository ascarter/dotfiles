--- lua-language-server
--- https://github.com/luals/lua-language-server

---@type vim.lsp.Config
return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = {
    { '.luarc.json', '.luarc.jsonc', '.emmyrc.json' },
    { '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml' },
    { '.git' },
  },
  settings = {
    Lua = {
      runtime   = { version = 'LuaJIT' },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
      codeLens  = { enable = true },
      hint      = { enable = true, semicolon = 'Disable' },
      telemetry = { enable = false },
    },
  },
}
