# dotfiles

A personal developer environment for macOS and Linux (Fedora Atomic). It covers two
concerns in one repository:

1. **Configuration** — editor, shell, git, and tool settings, symlinked into
   `~/.config` via `dotfiles sync`.
2. **Bootstrap and tools** — OS provisioning, shell wiring, and a tool management
   system (`dotfiles tool`) that installs GitHub-release binaries into a clean,
   versioned layout under `~/.local/opt`.

---

## Filesystem Layout

This project is designed around the [XDG Base Directory Specification][xdg], which
keeps every file out of `$HOME` and in a well-known, purpose-specific directory.
Three additional `XDG_OPT_*` variables extend the standard to cover opt-managed
tool installations.

```
$HOME/
├── .config/              XDG_CONFIG_HOME   runtime config (managed by dotfiles sync)
│   ├── git/
│   ├── zsh/
│   ├── nvim/
│   └── …
│
├── .local/
│   ├── bin/              XDG_BIN_HOME      user binaries — self-installing tools
│   │                                       (zed, claude, fnm, rustup, uv, …)
│   │
│   ├── opt/              XDG_OPT_HOME      opt-managed tools (dotfiles tool)
│   │   ├── bin/          XDG_OPT_BIN       symlinks to installed binaries  [on PATH]
│   │   ├── share/        XDG_OPT_SHARE     symlinks to man pages/completions [on MANPATH]
│   │   └── cellar/                         versioned extracted assets
│   │       └── <name>/
│   │           └── <tag>/
│   │               └── <binary>
│   │
│   ├── share/            XDG_DATA_HOME     application data
│   │   └── dotfiles/     DOTFILES_HOME     this repository
│   │
│   └── state/            XDG_STATE_HOME    persistent runtime state
│       └── tools/                          installed version receipts
│           └── <name>                      one file per tool, contains the tag
│
└── .cache/               XDG_CACHE_HOME    ephemeral data — safe to delete at any time
    └── tools/                              downloaded release archives
        └── <name>/
            └── <asset>
```

### Why XDG?

The XDG Base Directory Specification separates files by their intended lifecycle:

| Directory | Variable | Lifecycle |
|-----------|----------|-----------|
| `~/.config` | `XDG_CONFIG_HOME` | Permanent — checked in, synced |
| `~/.local/share` | `XDG_DATA_HOME` | Permanent — application data |
| `~/.local/state` | `XDG_STATE_HOME` | Persistent — survives reboots, not synced |
| `~/.cache` | `XDG_CACHE_HOME` | Ephemeral — always safe to delete |
| `~/.local/bin` | `XDG_BIN_HOME` | Permanent — user-local binaries |
| `~/.local/opt` | `XDG_OPT_HOME` | Permanent — opt-managed versioned tools |

`~/.cache` in particular can always be deleted without losing anything important.
`dotfiles tool clean` prunes `~/.cache/tools/` specifically. Version state (which
tag is installed) is kept in `~/.local/state/tools/` and survives a cache wipe.

### Tool Install Destinations

Two different bin directories serve different purposes deliberately:

- **`~/.local/bin` (`XDG_BIN_HOME`)** — tools that ship their own installer
  (`curl | sh`). zed, claude, fnm, rustup, uv all land here. dotfiles does not
  manage these symlinks.

- **`~/.local/opt/bin` (`XDG_OPT_BIN`)** — symlinks created by `dotfiles tool
  install`, pointing into `~/.local/opt/cellar/<name>/<tag>/`. These are fully
  managed: `dotfiles tool uninstall` removes the cellar and prunes broken symlinks.

The separation means `dotfiles tool uninstall` can safely remove everything it owns
in `XDG_OPT_BIN` without risk of touching tools it did not install.

---

## Installation

### Quick install

Bootstrap a new machine with a single command:

```sh
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dotfiles/main/install.sh)"
```

### Manual install

```sh
git clone https://github.com/ascarter/dotfiles.git ~/.local/share/dotfiles
cd ~/.local/share/dotfiles
./install.sh
```

`install.sh` clones the repo if not present, then runs `dotfiles init` and
`dotfiles sync`. It does not install tools — run `dotfiles tool install` separately
once `gh` is available (see below).

### Tool installation

Tool installation requires the GitHub CLI (`gh`) to download release assets:

```sh
# Install gh first (macOS: via Brewfile; Fedora: dotfiles script tools/gh)
dotfiles tool install
```

On Fedora Atomic, `rpm-ostree` operations from `dotfiles init` require a reboot
before `gh` is available. Run `dotfiles tool install` after that reboot.

### Uninstall

```sh
# Remove config symlinks and optionally delete the repo
./uninstall.sh

# Remove all opt-managed tools (keeps cache)
dotfiles tool uninstall

# Clear cached archives
dotfiles tool clean
```

---

## Usage

```sh
dotfiles init                   # Full bootstrap: XDG dirs, shell, sync, OS provisioning
dotfiles sync                   # Symlink config/ into ~/.config
dotfiles status                 # Show symlink drift
dotfiles update                 # Pull latest and re-sync

dotfiles tool install           # Install all tools
dotfiles tool install <name>    # Install one tool
dotfiles tool uninstall [name]  # Remove tool(s) from cellar; keeps cache
dotfiles tool clean [name]      # Clear downloaded archives

dotfiles script <name>          # Run a script from scripts/
```

---

## Contributing

- Start with `AGENTS.md` for repository guidelines and conventions.
- See `docs/dev-environment.md` for implementation details and rebuild flow.
- Track tool work in `docs/tools-backlog.md`.

[xdg]: https://specifications.freedesktop.org/basedir-spec/latest/
