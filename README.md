# dotfiles

Personal workstation environment for macOS and Linux (Fedora Atomic).

This repository makes a machine become a personal workstation. It is **not** a
package manager — it bootstraps the OS, syncs configuration, and wires the shell
so that native tools handle everything else.

---

## Quick Start

```sh
# Bootstrap a new machine
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dotfiles/main/install.sh)"
dotfiles host init
```

Or clone manually:

```sh
git clone https://github.com/ascarter/dotfiles.git ~/.local/share/dotfiles
cd ~/.local/share/dotfiles && ./install.sh
dotfiles host init
```

`install.sh` clones the repo (if needed), runs `dotfiles init` and
`dotfiles sync`. Host provisioning (`dotfiles host init`) installs platform
packages, sets up aqua, and applies OS defaults.

---

## Usage

```sh
dotfiles init                   # Bootstrap XDG dirs, shell wiring, sync
dotfiles sync                   # Symlink config/ into ~/.config
dotfiles status                 # Show sync state
dotfiles update                 # git pull + re-sync
dotfiles host init              # OS provisioning (auto-detects macos|fedora-atomic|toolbox)
dotfiles host status            # Show host environment info
dotfiles doctor                 # Check workstation health
dotfiles gitconfig              # Generate machine-specific ~/.gitconfig
dotfiles script <name>          # Run a script from scripts/
dotfiles env                    # Emit zsh environment setup (sourced by .zshenv)
```

For daily tool and package maintenance, use native commands directly:

```sh
brew update && brew upgrade             # macOS packages
aqua update && aqua i -a               # workstation CLI tools
dotfiles update && dotfiles sync       # config and repo
```

---

## Layer Model

| Layer | Scope | Managed by |
|-------|-------|------------|
| **1. Host OS baseline** | System packages, drivers, desktop apps | `brew`, `rpm-ostree`, `dnf` |
| **2. Workstation CLI tools** | Portable CLI binaries (ripgrep, fzf, jq, delta, …) | [aqua](https://aquaproj.github.io) (`config/aquaproj-aqua/`) |
| **3. Language version managers** | rustup, uv, fnm | Managed by aqua or standalone installers |
| **4. Project-local environments** | `.envrc`, `devcontainer.json`, per-repo tooling | Owned by each project — not this repo |

---

## Repository Structure

```
.
├── AGENTS.md                  # Contributor and agent guidelines
├── README.md
├── install.sh                 # Bootstrap entrypoint
├── bin/dotfiles               # CLI entrypoint
├── config/
│   ├── aquaproj-aqua/         # Global aqua tool manifests
│   ├── zsh/                   # Shell config
│   ├── git/                   # Git config
│   ├── nvim/                  # Neovim config
│   ├── zed/                   # Zed config
│   └── …
├── host/
│   ├── macos/                 # bootstrap.sh, Brewfile, defaults.sh
│   ├── fedora-atomic/         # bootstrap.sh, overlay-packages.txt
│   └── toolbox/               # bootstrap.sh, dnf-packages.txt
├── lib/logging.sh             # Shared logging/utility functions
├── scripts/                   # Standalone helper scripts
└── docs/                      # Architecture and reference docs
```

---

## XDG Layout

All paths follow the [XDG Base Directory Specification][xdg]. Nothing is written
directly to `$HOME`.

| Directory | Variable | Purpose |
|-----------|----------|---------|
| `~/.config` | `XDG_CONFIG_HOME` | Dotfiles-managed configuration |
| `~/.local/share` | `XDG_DATA_HOME` | Application data; dotfiles repo home |
| `~/.local/bin` | `XDG_BIN_HOME` | User scripts and standalone binaries |
| `~/.local/state` | `XDG_STATE_HOME` | Persistent runtime state |
| `~/.cache` | `XDG_CACHE_HOME` | Ephemeral caches — safe to delete |

Aqua uses standard XDG paths:

- `AQUA_GLOBAL_CONFIG` → `$XDG_CONFIG_HOME/aquaproj-aqua/aqua.yaml`
- `AQUA_ROOT_DIR` → `$XDG_DATA_HOME/aquaproj-aqua`

---

## Shell Environment

`~/.zshenv` contains a single bootstrap line:

```sh
eval "$($HOME/.local/share/dotfiles/bin/dotfiles env)"
```

`dotfiles env` exports XDG defaults, `ZDOTDIR`, `DOTFILES_HOME`, aqua config
paths, and PATH additions. The repo owns zsh initialization; everything else
is configured through files in `config/zsh/`.

---

## Uninstall

```sh
./uninstall.sh          # Remove config symlinks and optionally delete the repo
```

---

## Contributing

Start with [`AGENTS.md`](AGENTS.md) for repository guidelines and conventions.
See [`docs/`](docs/) for architecture and host-bootstrap reference.

---

## License

[MIT](LICENSE) © Andrew Carter

[xdg]: https://specifications.freedesktop.org/basedir-spec/latest/
