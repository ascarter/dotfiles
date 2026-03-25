# Repository Guidelines

## Start Here (Single Entry Point)
Use this file as the canonical contributor and agent entrypoint. Read `AGENTS.md` first, then open supporting docs from the map below as needed.

Conflict rule:
- If guidance differs between files, follow `AGENTS.md` and then update the other document to match.

## Documentation Map
- `README.md`: install/bootstrap quick start.
- `docs/dev-environment.md`: detailed lifecycle, tier model, and implementation patterns.
- `docs/tool-system.md`: tool system reference — recipe format, config variables, hooks, driver flow.
- `docs/font-system.md`: font system reference — recipe format, config variables, hooks, driver flow.
- `.github/copilot-instructions.md`: thin pointer for coding assistants back to this file.

## Project Structure & Module Organization
- `bin/dotfiles`: primary CLI entrypoint (`init`, `shell`, `env`, `sync`, `status`, `update`, `edit`, `host`, `tool`, `font`, `cache`, `gitconfig`, `script`).
- `config/`: source-of-truth configs synced into `$XDG_CONFIG_HOME`.
- `lib/core.sh`: sourced library; tty/logging functions (`log`, `warn`, `error`, `abort`, `ensure`, `success`).
- `lib/sync.sh`: sourced library; `_sync` implementation for link/unlink/status modes.
- `lib/tool.sh`: sourced library; `dotfiles tool` subcommand implementation (`_tool_cmd` and helpers).
- `lib/opt.sh`: sourced installer library; declares `XDG_OPT_*` vars, provides `tool_gh_install`, `tool_link`, `tool_latest_tag`, `tool_installed_tag`, and the declarative tool driver (`tool_run_recipe`).
- `lib/font.sh`: sourced library; `dotfiles font` subcommand implementation (`_font_cmd`, `font_run_recipe`, `font_gh_install`); sources `lib/opt.sh` for storage paths.
- `lib/cache.sh`: sourced library; `dotfiles cache` subcommand implementation (`_cache_cmd`); shows and clears the shared download cache.
- `lib/os/fedora/pkg.sh`: Fedora package management helper (dnf/rpm-ostree); called by tool scripts.
- `lib/os/fedora/repo.sh`: Fedora repo management helper; called by tool scripts.
- `tools/`: flat directory of tool recipes and installer scripts, one per tool capability.
- `fonts/`: flat directory of font recipes, one per font family. See `docs/font-system.md`.
- `host/<platform>.sh`: OS baseline provisioning; one script per environment (`macos.sh`, `fedora.sh`, `toolbox.sh`).
- `config/zsh/functions/_dotfiles`: zsh completion function for the `dotfiles` CLI (auto-registered via `compinit`).
- `scripts/*.sh`: convenience and orchestration scripts (e.g. `gitconfig.sh`, `developer.sh`).

## Tool Script Categories

Tools in `tools/` use one of two formats: **declarative recipes** (preferred) or
**imperative scripts** (legacy). The driver auto-detects based on shebang presence.
Every recipe declares `TOOL_TYPE` to identify how the tool is acquired.
See `docs/tool-system.md` for the full reference on writing recipes, config variables,
hooks, and driver flow.

**Keep `docs/tool-system.md` up to date when changing the tool system** — it is the
canonical reference for recipe format, config variables, hooks, and driver behavior.

### Recipe types

| Type | Description | Examples |
|------|-------------|----------|
| `github` | Download from GitHub releases | fzf, ripgrep, just |
| `appimage` | Linux AppImage with desktop integration (driver handles platform gate, linking, desktop entry) | ghostty, obsidian |
| `installer` | Curl-based vendor install script | uv, rustup, claude |
| `custom` | Bespoke download/install logic | gh, go, vscode |

### Quick recipe example (github)

```bash
# tools/fzf.sh — pure config, no logic needed
TOOL_CMD=fzf
TOOL_TYPE=github
TOOL_REPO=junegunn/fzf
TOOL_ASSET_MACOS_ARM64="fzf-*-darwin_arm64.tar.gz"
TOOL_ASSET_LINUX_ARM64="fzf-*-linux_arm64.tar.gz"
TOOL_ASSET_LINUX_AMD64="fzf-*-linux_amd64.tar.gz"
TOOL_LINKS=(fzf)
```

### Quick recipe example (appimage)

```bash
# tools/ghostty.sh — fully declarative, zero hooks
TOOL_CMD=ghostty
TOOL_TYPE=appimage
TOOL_REPO=pkgforge-dev/ghostty-appimage
TOOL_ASSET_LINUX_ARM64="Ghostty-*-aarch64.AppImage"
TOOL_ASSET_LINUX_AMD64="Ghostty-*-x86_64.AppImage"
TOOL_DESKTOP_ID=com.mitchellh.ghostty
TOOL_DESKTOP_EXEC="ghostty --font-size=10"
TOOL_BREW=ghostty
```

### Imperative scripts (shebang present — legacy)

Self-contained bash scripts that source `lib/opt.sh` and call functions directly.
Used only when hook functions cannot express the install flow.

No imperative scripts exist today — all tools use declarative recipes with hooks.

## Font Recipes

Font recipes in `fonts/` follow a similar declarative pattern to tool recipes.
The driver (`lib/font.sh`) sources a recipe to load variables and optional hooks,
then downloads, extracts, and copies TTF files to the OS font directory.

See `docs/font-system.md` for the full reference on writing recipes, config variables,
hooks, and driver flow.

**Keep `docs/font-system.md` up to date when changing the font system.**

### Quick recipe example

```bash
# fonts/juliamono.sh — pure config, no logic needed
FONT_REPO=cormullion/juliamono
FONT_ASSET="JuliaMono-ttf.tar.gz"
```

### Custom tag resolution (IBM Plex)

Repos with non-standard release tags use a `font_latest_tag` hook:

```bash
# fonts/ibm-plex-mono.sh
FONT_REPO=IBM/plex
FONT_ASSET="ibm-plex-mono.zip"
FONT_GLOB="fonts/complete/ttf/*.ttf"
FONT_STRIP_COMPONENTS=1

font_latest_tag() {
  gh release list --repo IBM/plex --limit 100 \
    --json tagName,isDraft,isPrerelease \
    --jq 'map(select((.isDraft | not) and (.isPrerelease | not) and (.tagName | startswith("@ibm/plex-mono@"))))[0].tagName'
}
```

## XDG_OPT_* Convention

`dotfiles` declares three XDG-style variables as a first-class peer of the standard XDG dirs.
They are exported by `cmd_env` and set with fallbacks by `lib/opt.sh`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `XDG_OPT_HOME` | `~/.local/opt` | Root for opt-managed tool installations |
| `XDG_OPT_BIN` | `$XDG_OPT_HOME/bin` | Symlink farm for binaries (on PATH) |
| `XDG_OPT_SHARE` | `$XDG_OPT_HOME/share` | Symlink farm for man pages and completions (on MANPATH) |

`XDG_OPT_BIN` is prepended to `PATH`; `XDG_OPT_SHARE/man` is prepended to `MANPATH`.

## Tool Storage Layout

```
~/.local/opt/                          XDG_OPT_HOME
  bin/                                 XDG_OPT_BIN   — symlinks to installed binaries
  share/                               XDG_OPT_SHARE — symlinks to man pages, completions
  cellar/                              TOOLS_CELLAR  — versioned extracted assets
    <name>/
      <version>/                       normalized version (e.g. 0.70.0, not v0.70.0)

~/.cache/dotfiles/tools/               TOOLS_CACHE   — downloaded archives
  <name>/

~/.local/state/dotfiles/tools/         TOOLS_STATE   — installed version receipts
  <name>                               one file per tool, contains the normalized version
```

`XDG_OPT_HOME` is self-contained: `rm -rf ~/.local/opt` removes all opt-managed tools
and their symlinks. Cache and state are separate and survive an uninstall.

## Build, Test, and Development Commands
- `./install.sh`: bootstrap repository to `$XDG_DATA_HOME/dotfiles`.
- `bin/dotfiles init`: set up XDG dirs, wire shell, and sync config.
- `bin/dotfiles host init`: run OS baseline provisioning (auto-detects `macos`, `fedora`, `toolbox`).
- `bin/dotfiles host status`: show detected host environment info.
- `bin/dotfiles gitconfig`: generate machine-specific `~/.gitconfig`.
- `bin/dotfiles sync`: symlink `config/` into `$XDG_CONFIG_HOME`.
- `bin/dotfiles tool install`: install all tools in `tools/` (auto-bootstraps `gh` via curl if not already installed).
- `bin/dotfiles tool install <name>`: install a single tool by name.
- `bin/dotfiles tool uninstall [<name>]`: remove installed tool(s); preserves cache.
- `bin/dotfiles tool uninstall --force [<name>]`: force removal even if cellar is missing (for broken installs).
- `bin/dotfiles tool outdated`: show tools with newer versions available.
- `bin/dotfiles tool clean [<name>]`: clear downloaded archives from cache.
- `bin/dotfiles tool cleanup [<name>]`: remove old cellar versions, keeping only the currently installed version.
- `bin/dotfiles font install`: install all fonts in `fonts/`.
- `bin/dotfiles font install <name>`: install a single font by name.
- `bin/dotfiles font list`: show installed fonts with versions.
- `bin/dotfiles cache status`: show download cache size and contents.
- `bin/dotfiles cache clean`: clear all downloaded archives from cache.
- `bin/dotfiles script <name>`: run a script from `scripts/` directly.
- `./test.sh`: smoke test install/sync in `.testuser/`.

## Coding Style & Naming Conventions
- Default shell: `#!/usr/bin/env bash` with `set -eu` for all scripts.
- Sourced libraries (`lib/*.sh`) have no shebang and do not use `set -e` internally.
- Keep scripts linear, explicit, idempotent, and re-runnable.
- Follow `.editorconfig` (2 spaces, UTF-8, LF, trailing newline).
- Name scripts by capability, not installer backend.
- Tool scripts self-locate via: `: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"`
- Host scripts self-locate one level deeper: `$(dirname "$0")/..` from `host/`.
- Use `XDG_OPT_*` vars for opt-space paths; use standard `XDG_*` vars for everything else.
- macOS support in this repo targets Apple Silicon only; do not add or consider Intel Mac recipe support unless explicitly requested.

## Zsh Completion

`config/zsh/functions/_dotfiles` provides tab-completion for the `dotfiles` CLI.
It is placed on `fpath` via `config/zsh/.zshrc` and auto-registered by `compinit`.

**Keep `_dotfiles` in sync with the CLI.** When you add, rename, or remove a
subcommand, flag, or argument in `bin/dotfiles` or `lib/*.sh`, update the
completion function to match. Dynamic arguments (tool names, font names, script
names, host environments) are discovered from the filesystem at completion time
and do not need manual updates.

## Testing Guidelines
- No unit test suite currently; validation is command/script based.
- Run `./test.sh` for bootstrap/sync changes.
- For tool script edits, run the script and verify `bin/dotfiles status`.

## Commit & Pull Request Guidelines
- Use short imperative commit subjects (for example: `Add dotfiles host status subcommand`).
- Keep commits scoped to one capability or lifecycle area.
- PRs should include changed behavior, impacted platforms, and validation commands run.

## Security & Configuration Tips
- Prefer XDG paths. For opt-managed tools use `$XDG_OPT_HOME`/`$XDG_OPT_BIN`/`$XDG_OPT_SHARE`.
- Keep host installs for OS-integrated needs; prefer opt-space installs otherwise.
- `gh` is self-managed via the tool system; it bootstraps itself using `curl` + GitHub REST API when not found. Run `dotfiles gitconfig` after initial install to authenticate.
