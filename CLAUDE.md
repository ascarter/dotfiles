# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Authoritative Reference

`AGENTS.md` is the canonical contributor guide. Read it first. For deeper implementation detail, see `docs/dev-environment.md`. This file summarizes the most relevant points for Claude Code.

## Commands

```sh
# Bootstrap and lifecycle
./install.sh                        # Bootstrap repo to $XDG_DATA_HOME/dotfiles
bin/dotfiles init                   # Dotfiles environment setup (XDG dirs, shell, sync)
bin/dotfiles host init              # OS provisioning — auto-detects macos|fedora|toolbox
bin/dotfiles host gitconfig         # Generate machine-specific ~/.gitconfig
bin/dotfiles shell                  # Wire ~/.zshenv to dotfiles env
bin/dotfiles sync                   # Symlink config/ into $XDG_CONFIG_HOME
bin/dotfiles status                 # Show symlink/state drift
bin/dotfiles update                 # Pull latest and re-sync
bin/dotfiles tool install           # Install all tools (requires gh installed first)
bin/dotfiles tool install <name>    # Install a single tool by name
bin/dotfiles tool uninstall [name]  # Remove tool(s) from cellar; keeps cache
bin/dotfiles tool clean [name]      # Clear downloaded archives from cache
bin/dotfiles script tools/gh        # Run a specific script from scripts/

# Testing
./test.sh                           # Smoke test install/sync in .testuser/ (requires rsync)

# Syntax checking
bash -n bin/dotfiles
bash -n lib/tool.sh
find tools/ host/ -name "*.sh" -exec bash -n {} \;

# After editing a tool script
bin/dotfiles status                 # Verify no drift
```

## Architecture

This repo manages a developer environment across macOS and Linux (Fedora/toolbox). The core mechanism is `bin/dotfiles`, a bash script with subcommands. `dotfiles sync` symlinks everything under `config/` into `$XDG_CONFIG_HOME` (default `~/.config`). The `env` subcommand is eval'd from `~/.zshenv` to export XDG variables and set PATH.

**Directory layout:**
- `lib/opt.sh` — sourced installer library; declares `XDG_OPT_*` vars and provides `tool_gh_install`, `tool_link`, `tool_latest_tag`, `tool_installed_tag`
- `tools/` — flat directory of tool installer scripts, one per tool; each sources `lib/opt.sh`
- `host/os/<platform>.sh` — OS baseline provisioning; one file per environment (`macos.sh`, `fedora.sh`, `toolbox.sh`)
- `host/config/` — host config generators (`gitconfig.sh`)
- `scripts/*.sh` — orchestration convenience scripts (`developer.sh`)

**XDG_OPT_* convention:**

`dotfiles` declares three variables as first-class peers of the standard XDG dirs, exported from `cmd_env` and set with fallbacks by `lib/tool.sh`:

```
XDG_OPT_HOME   ~/.local/opt        root for opt-managed installs
XDG_OPT_BIN    $XDG_OPT_HOME/bin   symlink farm — on PATH
XDG_OPT_SHARE  $XDG_OPT_HOME/share symlink farm — on MANPATH (share/man)
```

Inside `XDG_OPT_HOME`, versioned installs live under `cellar/<name>/<tag>/` (TOOLS_CELLAR).
`XDG_BIN_HOME` (~/.local/bin) is reserved for tools that self-install (zed, claude, fnm, rustup).

**Tier model for tool placement:**
- Host: OS-integrated tools (`git`, `zsh`, credential helpers)
- Layered/container image: stable CLI baseline (`rg`, `jq`, `yq`, `just`)
- `XDG_OPT_HOME` (opt-managed): GitHub release tools via `dotfiles tool install`
- `XDG_BIN_HOME` (~/.local/bin): tools with their own installers (zed, claude, fnm, rustup, uv)
- Per-project/toolbox: isolated project deps

**DOTFILES_HOME self-location pattern** (used in every tool and host script):
```bash
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"   # tool scripts
source "${DOTFILES_HOME}/lib/core.sh"  # host scripts
```

## Coding Style

- All scripts use `#!/usr/bin/env bash` with `set -eu`
- `lib/opt.sh` has no shebang (sourced) and no `set -e` internally
- Scripts must be linear, explicit, idempotent, and re-runnable
- Every tool script checks `command -v <tool>` at the top; skip silently if already installed
- Name scripts by capability, not installer backend
- Follow `.editorconfig`: 2-space indent, UTF-8, LF line endings, trailing newline
- Use `$XDG_OPT_HOME`/`$XDG_OPT_BIN`/`$XDG_OPT_SHARE` for opt-space paths
- Use standard `$XDG_*` vars (`XDG_DATA_HOME`, `XDG_CACHE_HOME`, etc.) for everything else

## Commits

- Short imperative subjects (e.g. `Refactor Fedora gh install flow with shared host helpers`)
- Scope commits to one capability or lifecycle area
