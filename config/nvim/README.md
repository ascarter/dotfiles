# Neovim Keymap Reference

Keymaps aligned with [Zed's vim mode](https://zed.dev/docs/vim) where possible,
layered on top of Neovim defaults. Leader is **Space**.

## LSP — Language Server

Mapped in `lua/plugins/lsp.lua` on `LspAttach` (buffer-local).

| Key | Action | Zed |
|-----|--------|-----|
| `gd` | Go to definition | ✅ |
| `gD` | Go to declaration | ✅ |
| `gy` | Go to type definition | ✅ |
| `gI` | Go to implementation | ✅ |
| `gh` | Hover (show docs) | ✅ |
| `g.` | Code actions (n, v) | ✅ |
| `cd` | Rename symbol | ✅ |
| `g]` | Next diagnostic | ✅ |
| `g[` | Previous diagnostic | ✅ |
| `]d` | Next diagnostic | ✅ · Neovim default |
| `[d` | Previous diagnostic | ✅ · Neovim default |
| `gA` | All references (fzf) | ✅ |
| `gs` | Document symbols (fzf) | ✅ |
| `gS` | Workspace symbols (fzf) | ✅ |
| `grr` | References (fzf) | Neovim default (overridden with fzf UI) |
| `grn` | Rename | Neovim default |
| `gra` | Code action | Neovim default |
| `K` | Hover | Neovim default |

## Tree-sitter — Text Objects & Motions

Mapped in `lua/plugins/treesitter.lua`. Provided by `nvim-treesitter-textobjects`.

### Text Objects (use with operators like `d`, `c`, `y`, `v`)

| Key | Action | Zed |
|-----|--------|-----|
| `af` | Around function | ✅ |
| `if` | Inside function | ✅ |
| `ac` | Around class/struct | ✅ |
| `ic` | Inside class/struct | ✅ |
| `aa` | Around argument | ✅ |
| `ia` | Inside argument | ✅ |

### Motions (jump between code structures)

| Key | Action | Zed |
|-----|--------|-----|
| `]m` / `[m` | Next / previous method start | ✅ |
| `]M` / `[M` | Next / previous method end | ✅ |
| `]]` / `[[` | Next / previous class start | ✅ |
| `][` / `[]` | Next / previous class end | ✅ |

## Find — fzf-lua

Mapped in `lua/plugins/fzf.lua`.

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Git files |
| `<leader>fr` | Recent files |
| `<leader>fh` | Help tags |
| `<leader>?` | Keymaps |
| `<leader>/` | Live grep (project search) |
| `<leader>sw` | Grep word under cursor |
| `<leader>sW` | Grep WORD under cursor |
| `<leader>sr` | Resume last picker |
| `<leader>bb` | List buffers |
| `<leader>cs` | Document symbols |
| `<leader>cS` | Workspace symbols |
| `<leader>cd` | Document diagnostics |
| `<leader>gc` | Git commits |
| `<leader>gs` | Git status |

## Debug — DAP

Mapped in `lua/plugins/dap.lua`.

| Key | Action |
|-----|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dc` | Continue |
| `<leader>dC` | Run to cursor |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dp` | Pause |
| `<leader>dr` | Restart |
| `<leader>dt` | Terminate |
| `<leader>dl` | Run last |
| `<leader>dR` | Open REPL |
| `<leader>du` | Toggle DAP UI |
| `<leader>de` | Evaluate (n, v) |
| `<F5>` | Continue |
| `<F9>` | Toggle breakpoint |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F12>` | Step out |

## Navigation & Editing

Mapped in `init.lua`.

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | Navigate splits |
| `<S-h>` | Previous buffer |
| `<S-l>` | Next buffer |
| `<leader>bd` | Close buffer |
| `y` / `Y` | Yank to system clipboard (n, v) |
| `<Esc>` | Clear search highlighting |
| `<Esc><Esc>` | Exit terminal mode |

## Completion (Insert Mode)

| Key | Action |
|-----|--------|
| `<C-Space>` | Trigger LSP completion |
| `<Tab>` | Accept completion / ghost text |
| `<C-y>` | Accept completion |
| `<Esc>` | Dismiss completion popup, exit insert |

## Surround — mini.surround

| Key | Action |
|-----|--------|
| `ys{motion}{char}` | Add surrounding |
| `ds{char}` | Delete surrounding |
| `cs{old}{new}` | Change surrounding |

## Format & Hints

| Key | Action |
|-----|--------|
| `<leader>cf` | Format (n, v) |
| `<leader>ci` | Toggle inlay hints |

## Zed Keymaps Not Adopted

These Zed vim-mode keymaps are intentionally omitted.

### Multi-cursor (no Neovim equivalent)

| Zed Key | Zed Action |
|---------|------------|
| `gl` | Add cursor at next match |
| `gL` | Add cursor at previous match |
| `ga` | Select all occurrences |
| `g>` | Skip selection, add next |
| `g<` | Skip selection, add previous |

Neovim workarounds: `*` highlights all matches, `cgn` changes one-at-a-time,
`grn`/`cd` does LSP rename across the project.

### Tree-sitter (partial — needs incremental selection)

| Zed Key | Zed Action |
|---------|------------|
| `]x` / `[x` | Expand / shrink syntax node |

### Git navigation (needs gitsigns or similar plugin)

| Zed Key | Zed Action |
|---------|------------|
| `]c` / `[c` | Next / previous git change |
| `do` | Expand diff hunk |
| `dp` | Revert change |
