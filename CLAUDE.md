# CLAUDE.md

Guidance for Claude Code. `AGENTS.md` is the canonical reference — read it first.
This file adds only Claude-specific quick-reference on top.

## Quick Command Reference

```sh
# Environment
bin/dotfiles init                   # XDG dirs, shell wiring, sync
bin/dotfiles host init              # OS provisioning (auto-detects macos|fedora-atomic|toolbox)
bin/dotfiles host status            # Show host environment info
bin/dotfiles gitconfig              # Generate machine-specific ~/.gitconfig
bin/dotfiles sync                   # Symlink config/ into $XDG_CONFIG_HOME
bin/dotfiles status                 # Show config sync state
bin/dotfiles update                 # Pull latest and re-sync
bin/dotfiles doctor                 # Check workstation health
bin/dotfiles script <name>          # Run a script from scripts/

# Syntax checking
bash -n bin/dotfiles
bash -n host/*/bootstrap.sh
```

## Self-Location Pattern

Host scripts resolve `DOTFILES_HOME` two levels up:

```bash
# host/*/bootstrap.sh
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"
```

## Commits

Short imperative subjects scoped to one capability area.

