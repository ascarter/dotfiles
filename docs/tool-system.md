# Tool System

The tool system manages self-contained tool installations in `~/.local/opt`,
isolated from the OS package manager. Tools are defined as **recipes** in `tools/`,
executed by a **driver** in `lib/opt.sh`, and orchestrated by `dotfiles tool` via `lib/tool.sh`.

## Commands

```sh
dotfiles tool install [<name>]     # Install all tools or a single tool
dotfiles tool upgrade [<name>]     # Upgrade to latest version
dotfiles tool outdated             # Show tools with newer versions available
dotfiles tool uninstall [<name>]   # Remove from cellar; preserves cache
dotfiles tool uninstall --force [<name>]  # Force removal even if cellar is missing
dotfiles tool clean [<name>]       # Clear downloaded archives from cache
dotfiles tool list                 # Show available tools, source type, and version
dotfiles -v tool list              # Include command path in output
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

### Bootstrap recipe example (curl-based, no gh dependency)

```bash
# tools/gh.sh — self-bootstrapping via curl + GitHub REST API
TOOL_CMD=gh
TOOL_REPO=cli/cli
TOOL_STRIP_COMPONENTS=1
TOOL_LINKS=(bin/gh)

tool_download() {
  local tag
  tag="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | \
    sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')"
  # ... resolve asset, download via curl, extract to cellar
}

tool_post_install() {
  tool_link "bin/gh" "bin/gh"
  for page in "${TOOLS_INSTALL_DIR}"/share/man/man1/gh*.1; do
    tool_link "share/man/man1/$(basename "$page")" "share/man/man1/$(basename "$page")"
  done
}
```

### AppImage example (Linux desktop app)

```bash
# tools/obsidian.sh — AppImage with desktop integration
TOOL_CMD=obsidian
TOOL_REPO=obsidianmd/obsidian-releases

tool_platform_check() {
  case "$(uname -s)" in
    Darwin) log "obsidian" "not found. Run: brew install --cask obsidian"; exit 1 ;;
    Linux)  ;;
    *)      error "Unsupported OS: $(uname -s)"; return 1 ;;
  esac
}

tool_download() {
  local tag version
  tag="$(tool_latest_tag "$TOOL_REPO")"
  version="${tag#v}"
  case "$(uname -m)" in
    x86_64)        tool_gh_install "$TOOL_REPO" "Obsidian-${version}.AppImage" "$tag" ;;
    aarch64|arm64) tool_gh_install "$TOOL_REPO" "Obsidian-${version}-arm64.AppImage" "$tag" ;;
    *)             error "Unsupported architecture: $(uname -m)"; return 1 ;;
  esac
}

tool_post_install() {
  tool_appimage_link "Obsidian-*.AppImage"
  tool_appimage_desktop "obsidian" "obsidian %u"
}

tool_uninstall() {
  tool_appimage_uninstall_desktop "obsidian"
}
```

## Config variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TOOL_CMD` | yes | Binary name for `command -v` check |
| `TOOL_REPO` | no | GitHub `owner/repo` (triggers gh-release flow using the latest non-draft, non-prerelease release by default) |
| `TOOL_ASSET_MACOS_ARM64` | if TOOL_REPO | Asset glob for macOS ARM64 |
| `TOOL_ASSET_LINUX_ARM64` | if TOOL_REPO | Asset glob for Linux ARM64 |
| `TOOL_ASSET_LINUX_AMD64` | if TOOL_REPO | Asset glob for Linux x86_64 |
| `TOOL_STRIP_COMPONENTS` | no | Strip N leading directory components during tar extraction (default: 0) |
| `TOOL_VERSION_ARGS` | no | Args passed to the binary to get version output (default: `--version`) |
| `TOOL_BREW` | no | Homebrew formula/cask name override when it differs from the tool name (e.g. `visual-studio-code` for vscode) |
| `TOOL_LINKS` | no | Array of symlink specs: `src:dst` or bare `name` (→ `name:bin/name`) |
| `TOOL_MAN_PAGES` | no | Array of man page paths to link (relative to install dir) |
| `TOOL_COMPLETIONS` | no | Array of completion files to link (relative to install dir) |

## Hook functions

Hooks override default driver behavior. Define them as functions in the recipe.

| Hook | Default | When to override |
|------|---------|------------------|
| `tool_download` | `tool_gh_install` using TOOL_REPO + resolved asset from the latest stable release | Custom APIs (go.dev), curl installers, package managers |
| `tool_post_install` | Symlink TOOL_LINKS, TOOL_MAN_PAGES, TOOL_COMPLETIONS | Plain binary rename (jq/yq), custom symlink layouts |
| `tool_platform_check` | Allow all platforms | Redirect to brew on macOS, restrict to specific distros |
| `tool_externally_managed` | False | Mark a recipe as externally managed on the current platform so batch install/upgrade skips it instead of failing |
| `tool_uninstall` | No-op | Custom cleanup before removal (e.g. `rustup self uninstall`) |
| `tool_upgrade` | Re-run install flow | Tools with self-update commands (e.g. `uv self update`) |

The completion log reports the resolved command path from `command -v` when available,
so self-managed installers can show their native location instead of always assuming
`$XDG_OPT_BIN/<tool>`.

## AppImage helpers

Shared helpers in `lib/opt.sh` for tools distributed as Linux AppImages.
Use these in `tool_post_install` and `tool_uninstall` hooks.

| Function | Description |
|----------|-------------|
| `tool_appimage_link <glob>` | Find AppImage matching glob in `TOOLS_INSTALL_DIR`, `chmod +x`, symlink to `TOOLS_BIN/$TOOL_CMD`. Sets `TOOL_APPIMAGE`. |
| `tool_appimage_desktop <desktop_id> <exec_line>` | Extract AppImage, install `.desktop` file and icon to XDG dirs, normalize `Exec=` line. Requires `TOOL_APPIMAGE` (call `tool_appimage_link` first). |
| `tool_appimage_uninstall_desktop <desktop_id> [icon_ext]` | Remove `.desktop` file and icon. `icon_ext` defaults to `png`. |

## Driver flow

### Bootstrap

When `dotfiles tool install` (or `upgrade`/`outdated`) runs and `gh` is not found
on PATH, the driver auto-bootstraps `gh` first using its curl-based `tool_download`
hook — no external dependency required. After bootstrap, a hint is printed:

```
[hint] run 'dotfiles gitconfig' to configure GitHub authentication and git identity
```

The `gh.sh` recipe uses `curl` + GitHub REST API for both initial install and
upgrades, so it never depends on itself. All other tools then use `gh` normally.

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
functions directly. Used only when hook functions cannot express the install flow.
Tools with complex platform-specific logic (e.g. desktop integration, AppImage
extraction) should use custom hooks (`tool_download`, `tool_post_install`,
`tool_uninstall`) instead.

## Implementation

| File | Role |
|------|------|
| `lib/opt.sh` | Tool primitives (`tool_gh_install`, `tool_link`, `tool_check`) and driver (`tool_run_recipe`, `tool_is_recipe`) |
| `lib/tool.sh` | CLI dispatcher (`_tool_cmd`), install/upgrade/uninstall/list/status/clean |
| `tools/*.sh` | Recipes and legacy scripts, one per tool |
