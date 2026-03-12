# Tool System

The tool system manages self-contained tool installations in `~/.local/opt`,
isolated from the OS package manager. Tools are defined as **recipes** in `tools/`,
executed by a **driver** in `lib/opt.sh`, and orchestrated by `dotfiles tool` via `lib/tool.sh`.

## Commands

```sh
dotfiles tool install [<name>]     # Install all tools or a single tool
dotfiles tool upgrade [<name>]     # Upgrade to latest version
dotfiles tool uninstall [<name>]   # Remove from cellar; preserves cache
dotfiles tool uninstall --force [<name>]  # Force removal even if cellar is missing
dotfiles tool clean [<name>]       # Clear downloaded archives from cache
dotfiles tool list                 # Show available tools and install status
dotfiles tool status               # Show paths, counts, and disk usage
```

## Writing a recipe

Recipes are plain config files in `tools/` — no shebang, no boilerplate. The driver
sources each recipe, loads its variables and optional hook functions, then executes
the install flow.

### Minimal example (GitHub release)

```bash
# tools/fzf.sh
TOOL_CMD=fzf
TOOL_REPO=junegunn/fzf
TOOL_ASSET_MACOS_ARM64="fzf-*-darwin_arm64.tar.gz"
TOOL_ASSET_MACOS_AMD64="fzf-*-darwin_amd64.tar.gz"
TOOL_ASSET_LINUX_ARM64="fzf-*-linux_arm64.tar.gz"
TOOL_ASSET_LINUX_AMD64="fzf-*-linux_amd64.tar.gz"
TOOL_LINKS=(fzf)
```

### Full example (GitHub release with strip, man pages, completions)

```bash
# tools/ripgrep.sh
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

### Curl installer example

```bash
# tools/uv.sh
TOOL_CMD=uv

tool_download() {
  curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
}
```

### Platform dispatch example

```bash
# tools/gh.sh
TOOL_CMD=gh

tool_platform_check() {
  case "$(uname -s)" in
    Darwin) log "gh" "not found. Run: brew install gh"; exit 1 ;;
  esac
}

tool_download() {
  . /etc/os-release
  case "${ID:-}" in
    fedora) bash "${DOTFILES_HOME}/lib/os/fedora/pkg.sh" install gh ;;
    *)      error "Unsupported: ${ID:-unknown}"; return 1 ;;
  esac
}
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
| `TOOL_STRIP_COMPONENTS` | no | Strip N leading directory components during tar extraction (default: 0) |
| `TOOL_LINKS` | no | Array of symlink specs: `src:dst` or bare `name` (→ `name:bin/name`) |
| `TOOL_MAN_PAGES` | no | Array of man page paths to link (relative to install dir) |
| `TOOL_COMPLETIONS` | no | Array of completion files to link (relative to install dir) |

## Hook functions

Hooks override default driver behavior. Define them as functions in the recipe.

| Hook | Default | When to override |
|------|---------|------------------|
| `tool_download` | `tool_gh_install` using TOOL_REPO + resolved asset | Custom APIs (go.dev), curl installers, package managers |
| `tool_post_install` | Symlink TOOL_LINKS, TOOL_MAN_PAGES, TOOL_COMPLETIONS | Plain binary rename (jq/yq), custom symlink layouts |
| `tool_platform_check` | Allow all platforms | Redirect to brew on macOS, restrict to specific distros |
| `tool_uninstall` | No-op | Custom cleanup before removal (e.g. `rustup self uninstall`) |

## Driver flow

### Install

```
1. Source recipe        — sets variables, optionally defines hook functions
2. tool_check           — skip if TOOL_CMD found (unless upgrading)
3. tool_platform_check  — hook or pass-through
4. tool_download        — hook or tool_gh_install with resolved asset
5. tool_post_install    — hook or default symlinks (errors on missing paths)
6. Log completion
```

### Uninstall

```
1. Source recipe        — load tool_uninstall hook if defined
2. tool_uninstall       — hook runs before any file deletions
3. Remove cellar dir    — delete TOOLS_CELLAR/<name>/
4. Remove state file    — delete TOOLS_STATE/<name>
5. Prune symlinks       — remove broken links from bin/ and share/
```

Use `--force` to skip the cellar existence check and continue past hook failures.
Useful for cleaning up broken or partial installs.

## Recipe vs legacy detection

The driver distinguishes recipes from legacy scripts by the first line:

- **No shebang** → recipe (sourced by `tool_run_recipe`)
- **Has shebang** (`#!/...`) → legacy script (run as `bash "$script"`)

Legacy scripts are self-contained bash scripts that source `lib/opt.sh` and call
functions directly. Used for tools with complex platform-specific logic like
desktop integration (ghostty, vscode).

## Implementation

| File | Role |
|------|------|
| `lib/opt.sh` | Tool primitives (`tool_gh_install`, `tool_link`, `tool_check`) and driver (`tool_run_recipe`, `tool_is_recipe`) |
| `lib/tool.sh` | CLI dispatcher (`_tool_cmd`), install/upgrade/uninstall/list/status/clean |
| `tools/*.sh` | Recipes and legacy scripts, one per tool |
