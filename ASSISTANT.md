# ASSISTANT.md

This file provides guidance to AI assistants when working with code in this repository.

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

## Coding Standards

* DRY but within reason.
* Implementing DRY principles should not lead to overly complex or unreadable code.
* Prefer simple patterns of repeated code across scripts over complex inclusion of shared code or configuration.
* Don't create functions that are called only once.
* Prefer POSIX-compliant syntax (#/bin/sh)
* Scripts should be idempotent
* Don't use emoji's or excessive colors.
* Prefer using bolding or italics over colors

## Project Rules
* Standardize logging to match dotfiles logging form
* Honor .editorconfig guidelines
* Use XDG environment variables
* NEVER hardcode anything that could be a secret or identifiable (like names or logins)

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
