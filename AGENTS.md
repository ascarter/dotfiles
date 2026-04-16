# Repository Guidelines

## Start Here (Single Entry Point)

Use this file as the canonical contributor and agent entrypoint for the dotfiles
repository. Read `AGENTS.md` first, then open supporting docs from the map below
only when more detail is needed.

Conflict rule: if guidance differs between files, follow `AGENTS.md` and update
the other document to match.

## Documentation Map

- `README.md` — install/bootstrap quick start.
- `docs/architecture.md` — layer model and design principles.
- `docs/host-bootstrap.md` — per-platform bootstrap reference.
- `docs/workstation-lifecycle.md` — daily workflows and maintenance.
- `.github/copilot-instructions.md` / `CLAUDE.md` — thin pointers back to this file.

## Design Principles

This repo manages **workstation profiles**, not packages. It is deliberately lean:

- **Not a package manager.** Tool installation is delegated to [gh-tool](https://github.com/ascarter/gh-tool), Homebrew, rpm-ostree, and dnf. Do not add wrapper commands that merely mirror native package-manager behavior.
- **`bin/dotfiles` is self-contained.** Config-sync logic is inlined; there is no separate `lib/sync.sh`.
- **`lib/logging.sh` is the primary shared library.** It provides logging/display utilities and is sourced by `bin/dotfiles`, host bootstrap scripts, and app scripts.
- **`lib/checksum.sh` provides portable SHA-256 verification.** Probes for `sha256sum` or `shasum` at source time.
- **`lib/appimage.sh` provides AppImage installation helpers.** Full lifecycle: resolve version, download, install, desktop integration. Used by AppImage installer scripts in `scripts/apps/`.
- **Host bootstrap uses native tools directly** — `brew bundle`, `rpm-ostree`, `dnf install`.
- **Project-local environments belong in each project**, not in this repo.
- **`XDG_OPT_*` variables no longer exist.** Use standard `XDG_*` variables only.

## Project Structure

```
bin/dotfiles              — primary CLI entrypoint (single self-contained script)
config/                   — source-of-truth configs synced into $XDG_CONFIG_HOME
  gh-tool/              — gh-tool manifest (config.toml)
  zsh/                    — zsh config (.zshrc, .zprofile, functions/, interactive.d/, profile.d/)
  git/ nvim/ zed/ ...     — app configs
host/                     — OS bootstrap scripts, one directory per environment
  macos/                  — init.sh, update.sh, Brewfile
  fedora-atomic/          — init.sh, update.sh, rpm-repos, overlay-rpms, flatpaks
  toolbox/                — init.sh, update.sh, rpm-repos, dnf-rpms
lib/logging.sh            — shared logging/utility library (sourced, no shebang)
lib/checksum.sh           — portable SHA-256 verification (sourced, no shebang)
lib/appimage.sh           — AppImage installation helpers (sourced, no shebang)
scripts/                  — standalone helper scripts (gitconfig.sh, developer.sh, etc.)
  apps/                   — app install/update scripts (claude, rustup, ghostty, etc.)
  host/                   — host provisioning scripts (homebrew, rpm-repos, gh-tool, etc.)
docs/                     — architecture, host-bootstrap, lifecycle docs
install.sh                — one-line bootstrap: clone repo → dotfiles init
test.sh                   — smoke test install/sync in .testuser/
```

## CLI Commands

`bin/dotfiles` is the single entrypoint. It supports these subcommands:

| Command | Description |
|---------|-------------|
| `dotfiles init` | Bootstrap XDG dirs, shell wiring, and sync config |
| `dotfiles shell` | Configure zsh and `.zshenv` bootstrap |
| `dotfiles env` | Emit zsh environment exports (eval'd by `.zshenv`) |
| `dotfiles sync` | Symlink `config/` into `~/.config` |
| `dotfiles uninstall` | Remove managed symlinks |
| `dotfiles status` | Show config sync state |
| `dotfiles update` | `git pull` + unlink + resync |
| `dotfiles doctor` | Check workstation health (XDG dirs, zshenv, sync) |
| `dotfiles host init [<env>]` | Run first-time OS provisioning (auto-detects macos, fedora-atomic, toolbox) |
| `dotfiles host update [<env>]` | Update host (dotfiles, packages, tools, apps) |
| `dotfiles host status` | Show detected host environment info |
| `dotfiles gitconfig` | Generate machine-specific `~/.gitconfig` |
| `dotfiles script <name>` | Run a script from `scripts/` (lists available if no name) |

## Environment Variables

`dotfiles env` emits the following (eval'd once from `~/.zshenv`):

| Variable | Value |
|----------|-------|
| `XDG_BIN_HOME` | `~/.local/bin` |
| `XDG_CONFIG_HOME` | `~/.config` |
| `XDG_DATA_HOME` | `~/.local/share` |
| `XDG_STATE_HOME` | `~/.local/state` |
| `XDG_CACHE_HOME` | `~/.cache` |
| `ZDOTDIR` | `$XDG_CONFIG_HOME/zsh` |
| `DOTFILES_HOME` | `$XDG_DATA_HOME/dotfiles` |

`PATH` is prepended with: `XDG_BIN_HOME` → `DOTFILES_HOME/bin`.

## Canonical Lifecycle

1. Install OS from scratch.
2. Bootstrap dotfiles: `install.sh` (or manual clone + `./install.sh`).
3. `dotfiles init` — XDG dirs, shell wiring, config sync.
4. `dotfiles host init` — OS baseline provisioning (reboot required on Fedora Atomic).
5. `dotfiles gitconfig` — machine-specific git identity and credentials.
6. `dotfiles host update` — install/update tools, apps, and packages.
7. Authenticate credentials and verify with `dotfiles doctor`.
8. Ongoing: run `dotfiles host update` periodically for maintenance.

## Tool Management (gh-tool)

CLI tool installation is delegated to **[gh-tool](https://github.com/ascarter/gh-tool)**,
a `gh` extension. Tool manifests live in `config/gh-tool/` and are synced into
`~/.config/gh-tool/` by `dotfiles sync`.

- Add a tool: edit `config/gh-tool/config.toml`, then run `gh tool install`.
- Remove a tool: delete its entry and run `gh tool install`.
- List installed tools: `gh tool list`.
- Upgrade tools: `gh tool upgrade`.

Do **not** add tool-install wrapper commands to `bin/dotfiles`. The CLI delegates
to gh-tool and does not reimplement package management.

## Host Bootstrap

Each supported environment has a directory under `host/` containing
`init.sh` (first-time provisioning) and `update.sh` (ongoing maintenance),
plus platform-specific package lists:

| Environment | Directory | Package manager |
|-------------|-----------|-----------------|
| macOS | `host/macos/` | Homebrew (`brew bundle`) |
| Fedora Atomic | `host/fedora-atomic/` | rpm-ostree overlay + dnf for toolbox |
| Toolbox | `host/toolbox/` | dnf |

`dotfiles host init` auto-detects the current environment and runs the matching
`init.sh`. Pass an explicit environment name to override.

`dotfiles host update` runs `dotfiles update` (git pull + resync), then the
platform `update.sh` which upgrades packages, gh tools, and runs app scripts.

## Coding Style & Naming Conventions

- Default shell: `#!/usr/bin/env bash` with `set -eu` for all scripts.
- Sourced libraries (`lib/logging.sh`, `lib/checksum.sh`, `lib/appimage.sh`) have no shebang and do not use `set -e` internally.
- Keep scripts linear, explicit, idempotent, and re-runnable.
- Follow `.editorconfig` (2 spaces, UTF-8, LF, trailing newline).
- `bin/dotfiles` self-locates via `realpath`.
- Host scripts self-locate: `: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"`.
- macOS support targets Apple Silicon only.

## Zsh Completion

`config/zsh/functions/_dotfiles` provides tab-completion for the CLI.
It is placed on `fpath` via `config/zsh/.zshrc` and auto-registered by `compinit`.

**Keep `_dotfiles` in sync with the CLI.** When you add, rename, or remove a
subcommand, flag, or argument in `bin/dotfiles`, update the completion function
to match. Dynamic arguments (script names, host environments) are discovered
from the filesystem at completion time and do not need manual updates.

## Testing & Validation

- `./test.sh` — smoke test install/sync in `.testuser/`.
- `bash -n bin/dotfiles` — syntax check the CLI.
- `find host/ lib/ scripts/ -name "*.sh" -exec bash -n {} \;` — syntax check all scripts.
- `bin/dotfiles status` — verify symlink state after changes.
- `bin/dotfiles doctor` — end-to-end workstation health check.

## Commit & Pull Request Guidelines

- Use short imperative commit subjects (e.g. `Add dotfiles doctor subcommand`).
- Keep commits scoped to one capability or lifecycle area.
- PRs should describe changed behavior, impacted platforms, and validation commands run.

## Security & Configuration Tips

- Use standard XDG paths for all storage.
- Keep host installs for OS-integrated needs; use gh-tool for CLI tools.
- `gh` self-bootstraps via curl when not found; run `dotfiles gitconfig` after install.

## Important Restrictions

- This repo is **not** and must **not** become a package manager.
- Do not add wrapper commands that merely mirror native gh-tool/brew behavior.
- Do not add `XDG_OPT_*` variables or opt-space tool management — that system was removed.
- Project-local environments belong in each project, not here.
