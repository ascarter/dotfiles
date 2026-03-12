# Refactor: Declarative tool driver

## Status: ✅ Complete

## Summary
Tool scripts were refactored from imperative bash scripts into declarative recipes.
A driver (`tool_run_recipe` in `lib/opt.sh`) sources each recipe to load config
variables and optional hook functions, then executes the standard install flow.

15 of 17 tools converted. ghostty and vscode remain legacy imperative scripts
due to complex platform-specific logic (AppImage/desktop integration).

## Recipe anatomy

```bash
# tools/ripgrep.sh — pure config with strip-components
TOOL_CMD=rg
TOOL_REPO=BurntSushi/ripgrep
TOOL_ASSET_MACOS_ARM64="ripgrep-*-aarch64-apple-darwin.tar.gz"
TOOL_ASSET_MACOS_AMD64="ripgrep-*-x86_64-apple-darwin.tar.gz"
TOOL_ASSET_LINUX_ARM64="ripgrep-*-aarch64-unknown-linux-gnu.tar.gz"
TOOL_ASSET_LINUX_AMD64="ripgrep-*-x86_64-unknown-linux-gnu.tar.gz"
TOOL_STRIP_COMPONENTS=1
TOOL_LINKS=(rg)
TOOL_MAN_PAGES=(doc/rg.1)
TOOL_COMPLETIONS=(complete/_rg complete/rg.bash)
```

## Config variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TOOL_CMD` | yes | Binary name for `command -v` check |
| `TOOL_REPO` | no | GitHub `owner/repo` (triggers gh-release flow) |
| `TOOL_ASSET_MACOS_ARM64` | if TOOL_REPO | Asset glob for macOS ARM64 |
| `TOOL_ASSET_MACOS_AMD64` | if TOOL_REPO | Asset glob for macOS x86_64 |
| `TOOL_ASSET_LINUX_ARM64` | if TOOL_REPO | Asset glob for Linux ARM64 |
| `TOOL_ASSET_LINUX_AMD64` | if TOOL_REPO | Asset glob for Linux x86_64 |
| `TOOL_STRIP_COMPONENTS` | no | Strip N leading directory components during extraction |
| `TOOL_LINKS` | no | Array of symlink specs: `src:dst` or bare `name` (→ `name:bin/name`) |
| `TOOL_MAN_PAGES` | no | Array of man page paths to link (relative to install dir) |
| `TOOL_COMPLETIONS` | no | Array of completion files to link (relative to install dir) |

## Hook functions (optional overrides)

| Hook | Default behavior | When to override |
|------|-----------------|------------------|
| `tool_download` | `tool_gh_install` using TOOL_REPO + asset | go (go.dev API), curl installers |
| `tool_post_install` | Create symlinks from TOOL_LINKS/MAN_PAGES/COMPLETIONS | jq/yq (plain binary rename), fnm (custom symlink) |
| `tool_platform_check` | Allow all | gh (macOS → "use brew") |

## Driver flow

```
1. Source recipe (sets vars, optionally defines hooks)
2. tool_check $TOOL_CMD               — skip if installed (unless upgrade)
3. tool_platform_check                 — bail with guidance if unsupported
4. tool_download                       — default: tool_gh_install
5. tool_post_install                   — default: create symlinks, error on missing paths
6. Log completion
```

## Tool categories

**Pure config (gh-release, no hooks):**
fzf, serie, just, tree-sitter, ripgrep

**Config + post_install hook:**
jq, yq (plain binary rename), fnm (custom symlink)

**Custom download hook:**
go (go.dev API + checksum), rustup, uv, rv, claude, zed (curl installers)

**Platform dispatch (platform_check + download hooks):**
gh (macOS → brew, Fedora → dnf)

**Legacy imperative scripts:**
ghostty (AppImage + desktop integration), vscode (tarball + desktop entry)

## Resolved design decisions
- Driver lives in `lib/opt.sh` (no separate file).
- Recipes are non-executable config files sourced by the driver (no shebang).
- Recipe detection: no shebang = recipe; shebang = legacy script.
- `TOOL_LINKS` uses `src:dst` syntax; bare `name` is shorthand for `name:bin/name`.
- Asset vars use readable platform names: `TOOL_ASSET_MACOS_ARM64`, etc.
- `TOOL_STRIP_COMPONENTS` handles tarballs with nested top-level directories.
- Path validation: `_tool_default_post_install` errors if declared paths don't exist.
- Curl installers use `tool_download` hook with full function body.
