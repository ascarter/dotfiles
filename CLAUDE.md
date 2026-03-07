# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Authoritative Reference

`AGENTS.md` is the canonical contributor guide. Read it first. For deeper implementation detail, see `docs/dev-environment.md`. This file summarizes the most relevant points for Claude Code.

## Commands

```sh
# Bootstrap and lifecycle
./install.sh                        # Bootstrap repo to $XDG_DATA_HOME/dotfiles
bin/dotfiles init                   # Full platform bootstrap (XDG dirs, shell, sync, OS init)
bin/dotfiles shell                  # Wire ~/.zshenv to dotfiles env
bin/dotfiles sync                   # Symlink config/ into $XDG_CONFIG_HOME
bin/dotfiles status                 # Show symlink/state drift
bin/dotfiles update                 # Pull latest and re-sync
bin/dotfiles script tools/gh        # Run a specific script from scripts/

# Testing
./test.sh                           # Smoke test install/sync in .testuser/ (requires rsync)

# After editing a tool script
bin/dotfiles status                 # Verify no drift
```

## Architecture

This repo manages a developer environment across macOS and Linux (Fedora/toolbox). The core mechanism is `bin/dotfiles`, a POSIX sh script with subcommands. `dotfiles sync` symlinks everything under `config/` into `$XDG_CONFIG_HOME` (default `~/.config`). The `env` subcommand is eval'd from `~/.zshenv` to export XDG variables and set PATH.

**Script organization by phase:**
- `scripts/host/os/<platform>/` — OS baseline provisioning (`init.sh`, `homebrew.sh`)
- `scripts/host/config/` — host config generators (`gitconfig.sh`, `toolbox-init.sh`)
- `scripts/tools/` — one installer per tool capability (`gh.sh`, `zed.sh`, etc.)
- `scripts/*.sh` — orchestration convenience scripts (`developer.sh`)

**Tier model for tool placement:**
- Host: OS-integrated tools (`git`, `zsh`, credential helpers)
- Layered/container image: stable CLI baseline (`rg`, `jq`, `yq`, `just`)
- User-local XDG (`$XDG_DATA_HOME`, `$XDG_BIN_HOME`): version managers and dev tools (`fnm`, `rustup`, `uv`, `helix`, `claude code`, etc.)
- Per-project/toolbox: isolated project deps

## Coding Style

- Default shell is POSIX `sh` with `set -eu`; use Bash only when required
- Scripts must be linear, explicit, idempotent, and re-runnable
- Name scripts by capability, not installer backend
- Follow `.editorconfig`: 2-space indent, UTF-8, LF line endings, trailing newline
- Prefer XDG paths (`$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, `$XDG_BIN_HOME`) over hardcoded paths

## Commits

- Short imperative subjects (e.g. `Refactor Fedora gh install flow with shared host helpers`)
- Scope commits to one capability or lifecycle area
