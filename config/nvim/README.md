# Neovim Keymap Reference

Keymaps aligned with [Zed's vim mode](https://zed.dev/docs/vim) where possible,
layered on top of Neovim defaults. Leader is **Space**.

## LSP — Language Server

Mapped in `lua/lsp.lua` on `LspAttach` (buffer-local).

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
| `gri` | Implementation | Neovim default |
| `grt` | Type definition | Neovim default |
| `grn` | Rename | Neovim default |
| `gra` | Code action | Neovim default |
| `grx` | Run code lens | Neovim default |
| `gO` | Document symbols | Neovim default |
| `K` | Hover | Neovim default |
| `<C-S>` (insert) | Signature help | Neovim default |
| `<C-W>d` / `<C-W><C-D>` | Show diagnostic float | Neovim default |

## Tree-sitter — Text Objects & Motions

Configured in `lua/treesitter.lua`.

Parsers are managed by [`tree-sitter-manager.nvim`](https://github.com/romus204/tree-sitter-manager.nvim).
Run `:TSManager` to install (`i`), update (`u`), or remove (`x`) parsers.

Three plugins layer over treesitter:

- [`nvim-treesitter-textobjects`](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)
  — language-aware text objects and motions (function, class, argument).
  Standalone, actively maintained.
- [`mini.ai`](https://github.com/nvim-mini/mini.ai) — heuristic
  language-agnostic text objects (brackets, quotes, custom delimiters) plus
  `n`/`l` modifiers and counts.
- [`mini.bracketed`](https://github.com/nvim-mini/mini.bracketed) — paired
  `]x` / `[x` motions for buffers, comments, diagnostics, indent, jumps,
  treesitter nodes, and more.

### Text Objects (use with operators like `d`, `c`, `y`, `v`)

Treesitter-aware (nvim-treesitter-textobjects):

| Key | Action | Zed |
|-----|--------|-----|
| `af` / `if` | Around / inside function definition | ✅ |
| `ac` / `ic` | Around / inside class/struct | ✅ |
| `aa` / `ia` | Around / inside argument | ✅ |

Heuristic, language-agnostic (mini.ai built-ins):

| Key | Action |
|-----|--------|
| `a(` `i(` `a)` `i)` `ab` `ib` | Parentheses / any bracket |
| `a[` `i[` `a]` `i]` | Square brackets |
| `a{` `i{` `a}` `i}` | Braces |
| `a<` `i<` `a>` `i>` | Angle brackets |
| `a"` `i"` `a'` `i'` `` a` `` `` i` `` `aq` `iq` | Quotes / any quote |
| `at` `it` | HTML/XML tag (heuristic) |
| `a?` `i?` | Prompt for custom delimiter pair |

mini.ai modifiers (work with any of the above):

| Key | Effect |
|-----|--------|
| `[count]` | Count-th occurrence (e.g. `v2i)`) |
| `an`/`in`/`al`/`il` | **Next** / **Last** instance (e.g. `dina` = delete inside next argument) |
| `g[` / `g]` | Jump to start / end of last text-object |

### Motions

Treesitter-aware (nvim-treesitter-textobjects):

| Key | Action | Zed |
|-----|--------|-----|
| `]m` / `[m` | Next / previous method start | ✅ |
| `]M` / `[M` | Next / previous method end | ✅ |
| `]]` / `[[` | Next / previous section start (class, falls back to function) | ✅ |
| `][` / `[]` | Next / previous section end (class, falls back to function) | ✅ |

Paired bracket motions (mini.bracketed + custom):

| Key | Target | Source |
|-----|--------|--------|
| `]b` / `[b` | Buffer (next/prev in buffer list) | mini.bracketed |
| `]/` / `[/` | Comment block | mini.bracketed (suffix remapped from `c`) |
| `]c` / `[c` | **Git hunk** (Zed parity) | gitsigns |
| `]d` / `[d` | Diagnostic | mini.bracketed |
| `]f` / `[f` | File in same directory | mini.bracketed |
| `]i` / `[i` | Indent change | mini.bracketed |
| `]j` / `[j` | Jumplist entry | mini.bracketed |
| `]l` / `[l` | Location-list entry | mini.bracketed |
| `]o` / `[o` | Oldfile (recent files) | mini.bracketed |
| `]q` / `[q` | Quickfix entry | mini.bracketed |
| `]t` / `[t` | Treesitter node (parent / sibling) | mini.bracketed |
| `]u` / `[u` | Undo state | mini.bracketed |
| `]w` / `[w` | Window | mini.bracketed |
| `]x` / `[x` | **Expand / shrink syntax node** (Zed parity) | custom (treesitter) |
| `]y` / `[y` | Yank entry (cycle paste history) | mini.bracketed |

Capital letter (`]B`, `[B`, etc.) jumps to the **last** / **first** match in
the buffer/list. `[count]` repeats N times.

See `:h MiniAi-textobject-builtin`, `:h mini.bracketed`, and
`:h nvim-treesitter-textobjects` for the full reference.

## Find — fzf-lua

Mapped in `lua/fzf.lua`.

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

> Git pickers (`<leader>gs`, `<leader>gh`, `<leader>gl`, `<leader>gL`,
> `<leader>gb`) live in the [Git](#git--gitsignsnvim) section.

## Debug — DAP

Mapped in `lua/debugging.lua`.

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

Mapped in `lua/keymaps.lua`.

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

Mapped in `lua/keymaps.lua` (with Neovim built-in fallthroughs).

| Key | Action |
|-----|--------|
| `<C-Space>` | Trigger LSP completion |
| `<Tab>` | Accept completion / ghost text, else insert tab |
| `<C-y>` | Accept completion |
| `<S-Tab>` | Jump in active snippet (Neovim default) |
| `<C-S>` | Show signature help (Neovim default) |
| `<Esc>` | Dismiss completion popup, exit insert |

## Editor — built-in & general

Comment, URL, and bracket helpers (Neovim 0.10+ defaults plus `mini.pairs`).

| Key | Action | Source |
|-----|--------|--------|
| `gc{motion}` | Toggle comment over motion | Neovim default |
| `gcc` | Toggle comment line | Neovim default |
| `gc` (visual / op-pending) | Toggle / target a comment block | Neovim default |
| `gx` | Open URL or filepath under cursor | Neovim default |
| `(` `)` `[` `]` `{` `}` `'` `"` `` ` `` (insert) | Auto-paired | mini.pairs |
| `<BS>` (insert) | Delete pair if cursor between matching pair | mini.pairs |

## Discovery — which-key

Configured in `lua/editor.lua`. Pressing a leader prefix (e.g. `<leader>`,
`<leader>g`, `g`, `]`, `[`) and pausing for ~300 ms shows the available
follow-up keys in a popup. Group labels are configured for `<leader>{b,c,d,f,g,s}`,
`g`, `]`, and `[`.

## Surround — mini.surround

Configured in `lua/editor.lua` with vim-surround style mappings (matches Zed).

| Key | Action |
|-----|--------|
| `ys{motion}{char}` | Add surrounding |
| `ds{char}` | Delete surrounding |
| `cs{old}{new}` | Replace (change) surrounding |
| `dsn` / `dsl` | Delete next / previous surrounding |
| `csn` / `csl` | Replace next / previous surrounding |

> Examples: `ysiw"` wraps the inner word in `"`, `ds(` deletes surrounding
> parens, `cs'"` replaces single with double quotes.

## Git — gitsigns.nvim

Configured in `lua/git.lua`.

Sign column shows added (`│`), changed (`│`), and deleted (`_`) markers. The
statusline shows the current branch and `+/~/-` counts when in a git repo.

### Hunk navigation (Zed parity)

| Key | Action | Zed |
|-----|--------|-----|
| `]c` / `[c` | Next / previous hunk | ✅ |
| `do` | Preview / expand hunk | ✅ |
| `dp` | Revert (reset) hunk | ✅ |
| `dO` | Toggle deleted-line view | ✅ |

### Hunk operations (`<leader>h*`)

| Key | Action |
|-----|--------|
| `<leader>hs` | Stage hunk (n, v) |
| `<leader>hr` | Reset hunk (n, v) |
| `<leader>hS` | Stage entire buffer |
| `<leader>hR` | Reset entire buffer |
| `<leader>hu` | Undo last hunk stage |
| `<leader>hb` | Blame current line (full) |
| `<leader>hB` | Toggle inline line blame |
| `<leader>hd` | Diff buffer against index |
| `<leader>hD` | Diff buffer against last commit |
| `ih` (operator-pending / visual) | Hunk text-object |

### Repo-wide git (`<leader>g*`)

| Key | Action |
|-----|--------|
| `<leader>gs` | Git status picker (changed files) |
| `<leader>gh` | Git hunks picker (every hunk in repo) |
| `<leader>gl` | Git log (repo) |
| `<leader>gL` | Git log (current buffer) |
| `<leader>gb` | Git branches picker |
| `<leader>gd` | Diff buffer against index (alias of `<leader>hd`) |
| `<leader>gD` | Diff buffer against last commit (alias of `<leader>hD`) |

## Format & Hints

Mapped in `lua/lsp.lua` on `LspAttach` (buffer-local).

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
