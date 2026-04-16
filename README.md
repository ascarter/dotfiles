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
packages, sets up gh-tool, and applies OS defaults.

---

## Usage

```sh
dotfiles init                   # Bootstrap XDG dirs, shell wiring, sync
dotfiles shell                  # Configure zsh and .zshenv bootstrap
dotfiles env                    # Emit zsh environment exports (eval'd by .zshenv)
dotfiles sync                   # Symlink config/ into ~/.config
dotfiles uninstall              # Remove managed symlinks
dotfiles status                 # Show sync state
dotfiles update                 # git pull + re-sync
dotfiles doctor                 # Check workstation health
dotfiles host init [<env>]      # OS provisioning (auto-detects macos|fedora-atomic|toolbox)
dotfiles host update [<env>]    # Update host (dotfiles, packages, tools, apps)
dotfiles host status            # Show host environment info
dotfiles gitconfig              # Generate machine-specific ~/.gitconfig
dotfiles script <name>          # Run a script from scripts/
```

For ongoing maintenance, `dotfiles host update` handles everything — pulls the
latest repo, re-syncs config, upgrades platform packages, gh tools, and apps:

```sh
dotfiles host update                    # all-in-one maintenance
```

---

## Layer Model

| Layer | Scope | Managed by |
|-------|-------|------------|
| **1. Host OS baseline** | System packages, drivers, desktop apps | `brew`, `rpm-ostree`, `dnf` |
| **2. Workstation CLI tools** | Portable CLI binaries (ripgrep, fzf, jq, fd, …) | [gh-tool](https://github.com/ascarter/gh-tool) (`config/gh-tool/`) |
| **3. Language version managers** | rustup, uv, fnm | Standalone installers |
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
│   ├── gh-tool/               # gh-tool manifest (config.toml)
│   ├── zsh/                   # Shell config (.zshrc, .zprofile, functions/, env.d/, interactive.d/)
│   ├── git/ ghostty/ nvim/    # App configs
│   ├── zed/ helix/ vim/ …     #
│   └── …
├── host/
│   ├── macos/                 # init.sh, update.sh
│   ├── fedora-atomic/         # init.sh, update.sh, overlay-rpms, rpm-repos, flatpaks
│   └── toolbox/               # init.sh, update.sh, rpm-repos, dnf-rpms
├── lib/
│   ├── logging.sh             # Shared logging/display utilities
│   ├── checksum.sh            # Portable SHA-256 verification
│   ├── appimage.sh            # AppImage installation helpers
│   └── rpm.sh                 # RPM helper utilities
├── scripts/
│   ├── apps/                  # App install/update scripts (claude, rustup, ghostty, …)
│   ├── host/                  # Host provisioning scripts (homebrew, gh-tool, macos-defaults, …)
│   └── misc/                  # Miscellaneous helper scripts
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

gh-tool configuration is synced into `$XDG_CONFIG_HOME/gh-tool/`.

---

## Shell Environment

`~/.zshenv` contains a single bootstrap line:

```sh
eval "$($HOME/.local/share/dotfiles/bin/dotfiles env)"
```

`dotfiles env` exports XDG defaults, `ZDOTDIR`, `DOTFILES_HOME`, and PATH additions. The repo owns zsh initialization; everything else
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
