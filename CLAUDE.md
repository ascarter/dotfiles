# CLAUDE.md

Guidance for Claude Code. `AGENTS.md` is the canonical reference — read it first.
This file adds only Claude-specific quick-reference on top.

## Quick Command Reference

```sh
# Environment
bin/dotfiles init                   # XDG dirs, shell wiring, sync
bin/dotfiles host init              # OS provisioning (auto-detects macos|fedora|toolbox)
bin/dotfiles host status            # Show host environment info
bin/dotfiles gitconfig              # Generate machine-specific ~/.gitconfig
bin/dotfiles sync                   # Symlink config/ into $XDG_CONFIG_HOME
bin/dotfiles status                 # Show symlink/tool drift
bin/dotfiles update                 # Pull latest and re-sync

# Tools
bin/dotfiles tool install           # Install all tools (requires gh first)
bin/dotfiles tool install <name>    # Install one tool
bin/dotfiles tool outdated          # Show tools with newer versions
bin/dotfiles tool uninstall [name]  # Remove from cellar; keeps cache
bin/dotfiles tool clean [name]      # Clear downloaded archives
bin/dotfiles script <name>          # Run a script from scripts/

# Syntax checking
bash -n bin/dotfiles
find tools/ host/ lib/ -name "*.sh" -exec bash -n {} \;
```

## Self-Location Pattern

Every script resolves `DOTFILES_HOME` at runtime so it works both standalone and
when called from `bin/dotfiles`:

```bash
# tools/ and scripts/ (one level down)
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"
source "${DOTFILES_HOME}/lib/opt.sh"    # tool installer scripts
source "${DOTFILES_HOME}/lib/core.sh"   # host/config scripts
```

## Commits

Short imperative subjects scoped to one capability area.
