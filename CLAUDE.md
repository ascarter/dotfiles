# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles management system that works across macOS and Linux platforms. The repository manages configuration files using symlinks and includes provisioning scripts for various tools and environments.

## Architecture

The dotfiles system is built around a central shell script (`bin/dotfiles`) that manages configuration through symlinks:

- **Configuration Source**: `src/` directory contains all configuration files in their target directory structure
- **Symlink Management**: The dotfiles tool creates symlinks from `$HOME` to files in `src/`
- **Shell Integration**: Automatic shell profile integration via `dotfiles init` command
- **XDG Base Directory Compliance**: Uses XDG environment variables for organization

### Key Components

- `bin/dotfiles` - Main configuration management tool
- `src/` - Source configuration files (mirrors target directory structure)
- `etc/` - Shell profile files (bashrc, zshrc, profile.d modules)
- `formula` - Homebrew formulas
- `scripts/` - Platform-specific provisioning scripts
- `install.sh` - Bootstrap installation script

## Common Commands

### Dotfiles Management
```bash
# Show status of all configuration files
./bin/dotfiles status

# Link all configuration files
./bin/dotfiles link

# Unlink all configuration files
./bin/dotfiles unlink

# Update dotfiles from git and re-link
./bin/dotfiles update

# Initialize shell integration
./bin/dotfiles init

# Run provisioning scripts
./bin/dotfiles script macos
./bin/dotfiles script developer
```

### Installation
```bash
# Fresh install (clones repo and links configs)
./install.sh

# Install with specific branch
./install.sh -b <branch-name>

# Uninstall (removes symlinks, restores backups)
./uninstall.sh
```

### Development
No build, test, or lint commands - this is a shell script-based configuration management system.

## Directory Structure

- `bin/` - The main dotfiles management script
- `etc/` - Shell profile configuration (bashrc, zshrc, profile.d modules)
- `scripts/` - Platform and tool-specific installation scripts
- `src/` - Configuration files in target directory structure (e.g., `src/.config/vim/vimrc` → `~/.config/vim/vimrc`)

## Script System

The `scripts/` directory contains idempotent provisioning scripts for:
- Platform setup (macos.sh, fedora.sh, ubuntu.sh)
- Development tools (developer.sh, github.sh, zed.sh)
- Applications (1password.sh, homebrew.sh, tailscale.sh)

All scripts can be run independently and repeatedly without issues.

## Key Environment Variables

- `DOTFILES` - Location of dotfiles repository (default: `$XDG_DATA_HOME/dotfiles`)
- `DOTFILES_CONFIG` - User config override directory (default: `$XDG_CONFIG_HOME/dotfiles`)
- `TARGET` - Target directory for symlinks (default: `$HOME`)

## Configuration Override

User-specific configurations can be placed in `$XDG_CONFIG_HOME/dotfiles/` to override defaults without modifying the main repository.
