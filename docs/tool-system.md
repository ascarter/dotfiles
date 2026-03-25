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

## Recipe types

Every recipe declares `TOOL_TYPE` to identify how the tool is acquired and managed.
The driver uses this to select the appropriate lifecycle behavior.

| Type | Description | Driver behavior |
|------|-------------|-----------------|
| `github` | Download binary from GitHub releases | Default: resolve asset → `tool_gh_install` → symlink `TOOL_LINKS` |
| `appimage` | Linux AppImage with desktop integration | Auto: platform gate (macOS → brew hint), `tool_appimage_link` + desktop entry, metadata-based versioning |
| `installer` | Curl-based vendor install script | Auto: `curl -fsSL $TOOL_INSTALL_URL \| env $TOOL_INSTALL_ENV bash -s -- $TOOL_INSTALL_ARGS` |
| `custom` | Bespoke download/install logic | Skipped in batch install/upgrade/outdated — hooks handle full lifecycle when targeted |

## Writing a recipe

Recipes are plain config files in `tools/` — no shebang, no boilerplate. The driver
sources each recipe, loads its variables and optional hook functions, then executes
the install flow.

### Minimal example (GitHub release)

```bash
# tools/fzf.sh
TOOL_CMD=fzf
TOOL_TYPE=github
TOOL_REPO=junegunn/fzf
TOOL_ASSET_MACOS_ARM64="fzf-*-darwin_arm64.tar.gz"
TOOL_ASSET_LINUX_ARM64="fzf-*-linux_arm64.tar.gz"
TOOL_ASSET_LINUX_AMD64="fzf-*-linux_amd64.tar.gz"
TOOL_LINKS=(fzf)
```

### Full example (GitHub release with strip, man pages, completions)

```bash
# tools/rg.sh
TOOL_CMD=rg
TOOL_TYPE=github
TOOL_REPO=BurntSushi/ripgrep
TOOL_ASSET_MACOS_ARM64="ripgrep-*-aarch64-apple-darwin.tar.gz"
TOOL_ASSET_LINUX_ARM64="ripgrep-*-aarch64-unknown-linux-gnu.tar.gz"
TOOL_ASSET_LINUX_AMD64="ripgrep-*-x86_64-unknown-linux-gnu.tar.gz"
TOOL_STRIP_COMPONENTS=1
TOOL_LINKS=(rg)
TOOL_MAN_PAGES=(doc/rg.1)
TOOL_COMPLETIONS=(complete/_rg)
```

### Curl installer example

```bash
# tools/uv.sh — pure config, no hooks needed
TOOL_CMD=uv
TOOL_TYPE=installer
TOOL_UPGRADE_COMMAND="uv self update"
TOOL_INSTALL_URL="https://astral.sh/uv/install.sh"
TOOL_INSTALL_ENV="UV_NO_MODIFY_PATH=1"
```

### Curl installer with args

```bash
# tools/rustup.sh — install args passed after --
TOOL_CMD=rustup
TOOL_TYPE=installer
TOOL_UPGRADE_COMMAND="rustup self update"
TOOL_INSTALL_URL="https://sh.rustup.rs"
TOOL_INSTALL_ARGS="-y --no-modify-path"
TOOL_UNINSTALL_COMMAND="rustup self uninstall -y"
```

### Bootstrap recipe example (curl-based, no gh dependency)

```bash
# tools/gh.sh — self-bootstrapping via curl + GitHub REST API
TOOL_CMD=gh
TOOL_TYPE=custom
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

### AppImage example (declarative desktop app)

```bash
# tools/ghostty.sh — fully declarative, zero hooks needed
TOOL_CMD=ghostty
TOOL_TYPE=appimage
TOOL_REPO=pkgforge-dev/ghostty-appimage
TOOL_ASSET_LINUX_ARM64="Ghostty-*-aarch64.AppImage"
TOOL_ASSET_LINUX_AMD64="Ghostty-*-x86_64.AppImage"
TOOL_DESKTOP_ID=com.mitchellh.ghostty
TOOL_DESKTOP_EXEC="ghostty --font-size=10"
TOOL_BREW=ghostty
```

The `appimage` driver handles everything: platform gating (macOS → brew hint),
`tool_appimage_link`, desktop entry + icon installation, and uninstall cleanup.
No hooks are needed for the standard AppImage flow.

### AppImage with version interpolation

When asset filenames embed the version number without a stable architecture
suffix, use `TOOL_VERSION_MATCH` + `{version}` placeholders:

```bash
# tools/obsidian.sh — version-embedded asset names
TOOL_CMD=obsidian
TOOL_TYPE=appimage
TOOL_REPO=obsidianmd/obsidian-releases
TOOL_VERSION_MATCH="^v(.*)"
TOOL_ASSET_LINUX_AMD64="Obsidian-{version}.AppImage"
TOOL_ASSET_LINUX_ARM64="Obsidian-{version}-arm64.AppImage"
TOOL_DESKTOP_ID=obsidian
TOOL_DESKTOP_EXEC="obsidian %u"
TOOL_BREW=obsidian
```

## Config variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TOOL_CMD` | yes | Binary name for `command -v` check |
| `TOOL_TYPE` | yes | Recipe type: `github`, `appimage`, `installer`, `custom` |
| `TOOL_REPO` | if github/appimage | GitHub `owner/repo` (triggers gh-release flow using the latest non-draft, non-prerelease release by default) |
| `TOOL_ASSET_MACOS_ARM64` | if TOOL_REPO | Asset glob for macOS ARM64 (supports `{version}` interpolation) |
| `TOOL_ASSET_LINUX_ARM64` | if TOOL_REPO | Asset glob for Linux ARM64 (supports `{version}` interpolation) |
| `TOOL_ASSET_LINUX_AMD64` | if TOOL_REPO | Asset glob for Linux x86_64 (supports `{version}` interpolation) |
| `TOOL_STRIP_COMPONENTS` | no | Strip N leading directory components during tar extraction (default: 0) |
| `TOOL_VERSION_ARGS` | no | Args passed to the binary to get version output (default: `--version`) |
| `TOOL_VERSION_MATCH` | no | Bash regex applied to the release tag. Capture group 1 becomes `{version}` for asset interpolation and metadata version display. |
| `TOOL_UPGRADE_COMMAND` | no | Shell command to run for `dotfiles tool upgrade` (e.g. `uv self update`). Skipped when an explicit `tool_upgrade` hook is defined. |
| `TOOL_SKIP` | no | Array of lifecycle phases to skip in batch operations (e.g. `(install upgrade)`). Tools with self-managed updaters use this to opt out of batch install/upgrade while remaining targetable individually. |
| `TOOL_BREW` | no | Homebrew formula/cask name override. Used in macOS platform-check hint for `appimage` type. |
| `TOOL_LINKS` | no | Array of symlink specs: `src:dst` or bare `name` (→ `name:bin/name`) |
| `TOOL_MAN_PAGES` | no | Array of man page paths to link (relative to install dir) |
| `TOOL_COMPLETIONS` | no | Array of completion specs: `src:dst` or bare path (basename used as dst). Paths relative to install dir, linked into `share/completions/`. Use `src:dst` to rename (e.g. `completions/foo.zsh:_foo`). |

### Installer-specific variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TOOL_INSTALL_URL` | if installer (no hook) | URL of the vendor install script (fetched with `curl -fsSL`) |
| `TOOL_INSTALL_ENV` | no | Space-separated `KEY=VALUE` pairs passed to `env` before bash (e.g. `UV_NO_MODIFY_PATH=1`) |
| `TOOL_INSTALL_ARGS` | no | Arguments passed to the install script after `--` (e.g. `-y --no-modify-path`) |
| `TOOL_UNINSTALL_COMMAND` | no | Shell command to run first during uninstall (e.g. `rustup self uninstall -y`). Runs before path/binary cleanup. |
| `TOOL_UNINSTALL_PATHS` | no | Array of data directories to remove on uninstall (e.g. version stores, depots). Removed after command, before hook. |

### AppImage-specific variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TOOL_DESKTOP_ID` | _(required)_ | Base name of the `.desktop` file (e.g. `com.mitchellh.ghostty`) |
| `TOOL_DESKTOP_EXEC` | `$TOOL_CMD` | `Exec=` line in the `.desktop` file |
| `TOOL_DESKTOP_ICON_EXT` | `png` | Icon file extension for uninstall cleanup |
| `TOOL_APPIMAGE_GLOB` | `*.AppImage` | Glob to find the AppImage in install dir (override if ambiguous) |

## Version interpolation

Asset patterns can contain `{version}` placeholders. When present, the driver:

1. Resolves the release tag via `tool_latest_tag` (or a `tool_latest_tag` hook)
2. If `TOOL_VERSION_MATCH` is set, applies the regex:
   `[[ "$tag" =~ ${TOOL_VERSION_MATCH} ]]` → capture group 1 is the version
3. If `TOOL_VERSION_MATCH` is not set, the raw tag is used as the version
4. Substitutes all `{version}` occurrences in the asset pattern
5. Passes the interpolated pattern + resolved tag to `tool_gh_install`

Patterns without `{version}` work as globs — this is fully backward-compatible.

## Hook functions

Hooks override default driver behavior. Define them as functions in the recipe.

| Hook | Default | When to override |
|------|---------|------------------|
| `tool_download` | `_tool_installer_download` for `installer` type with `TOOL_INSTALL_URL`, or `tool_gh_install` using TOOL_REPO + resolved asset for `github`/`appimage` types | Custom APIs (go.dev), non-standard install flows |
| `tool_post_install` | Symlink TOOL_LINKS, TOOL_MAN_PAGES, TOOL_COMPLETIONS (or AppImage link + desktop for `appimage` type) | Plain binary rename (jq/yq), custom symlink layouts |
| `tool_platform_check` | Allow all platforms (or Linux-only with macOS brew hint for `appimage` type) | Restrict to specific distros or architectures |
| `tool_externally_managed` | False (or true on macOS for `appimage` type) | Legacy hook — prefer `TOOL_SKIP=(install upgrade)` for new recipes. Kept for conditional platform logic. |
| `tool_uninstall` | Runs last in the uninstall pipeline (after command, paths, and type defaults) | Extra cleanup not covered by declarative variables |
| `tool_upgrade` | Run `TOOL_UPGRADE_COMMAND` if set, otherwise re-run install flow | Tools with self-update commands that need custom logic beyond a single command |

The completion log reports the resolved command path from `command -v` when available,
so self-managed installers can show their native location instead of always assuming
`$XDG_OPT_BIN/<tool>`.

## AppImage helpers

Shared helpers in `lib/opt.sh` for tools distributed as Linux AppImages.
For `TOOL_TYPE=appimage` recipes, these are called automatically by the driver.
They can also be called directly in hooks for custom AppImage workflows.

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
1. Source recipe           — sets variables, optionally defines hook functions
2. Externally managed      — hook or TOOL_TYPE=appimage default (macOS → skip)
3. tool_check              — skip if TOOL_CMD found (unless upgrading)
4. tool_platform_check     — hook or TOOL_TYPE=appimage default (macOS → brew hint)
5. Upgrade gate            — hook → TOOL_UPGRADE_COMMAND → fall through to normal flow
6. tool_download           — hook → TOOL_INSTALL_URL (installer driver) → tool_gh_install (github/appimage)
7. tool_post_install       — hook or TOOL_TYPE default (appimage: link + desktop; others: symlinks)
8. Log completion
```

### Uninstall

```
1. Source recipe           — load hooks and TOOL_TYPE
2. Uninstall pipeline:
   a. TOOL_UNINSTALL_COMMAND  — run self-uninstall command if set
   b. TOOL_UNINSTALL_PATHS   — remove declared data directories
   c. Type defaults           — installer: remove binary; appimage: remove desktop entry
   d. tool_uninstall hook     — custom cleanup (runs last)
3. Remove cellar dir       — delete TOOLS_CELLAR/<name>/
4. Remove state file       — delete TOOLS_STATE/<name>
5. Prune symlinks          — remove broken links from bin/ and share/
```

Use `--force` to skip the cellar existence check and continue past hook failures.
Useful for cleaning up broken or partial installs.

### Version detection

`dotfiles tool list` shows the installed version for each tool:

1. `tool_version` hook — if defined, explicit override always wins
2. State file tag — for `TOOL_TYPE=appimage`, reads the persisted tag from
   `TOOLS_STATE/<name>` and applies `TOOL_VERSION_MATCH` for display
3. Binary `--version` — default for other types (runs the binary with
   `TOOL_VERSION_ARGS` and extracts a version pattern)

## Recipe vs legacy detection

The driver distinguishes recipes from legacy scripts by the first line:

- **No shebang** → recipe (sourced by `tool_run_recipe`)
- **Has shebang** (`#!/...`) → legacy script (run as `bash "$script"`)

Legacy scripts are self-contained bash scripts that source `lib/opt.sh` and call
functions directly. Used only when hook functions cannot express the install flow.

## Implementation

| File | Role |
|------|------|
| `lib/opt.sh` | Framework: XDG layout, platform detection, version interpolation, recipe driver (`tool_run_recipe`) |
| `lib/opt/github.sh` | GitHub release driver: `tool_gh_install`, `tool_latest_tag`, asset resolution, default post-install |
| `lib/opt/appimage.sh` | AppImage driver: link, desktop integration, platform gate |
| `lib/opt/installer.sh` | Installer driver: `curl -fsSL` → `env` → `bash` pipeline |
| `lib/tool.sh` | CLI dispatcher (`_tool_cmd`), install/upgrade/uninstall/list/status/clean |
| `tools/*.sh` | Recipes and legacy scripts, one per tool |
