--- rust-analyzer — Rust language server
--- https://github.com/rust-lang/rust-analyzer

---@type vim.lsp.Config
return {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml', 'rust-project.json', '.git' },
}
