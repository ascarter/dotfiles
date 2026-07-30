# dotfiles

Personal workstation configuration for macOS and Fedora Atomic Linux, built
around [mise](https://mise.jdx.dev/).

> [!WARNING]
> This repository is an undeployed migration scaffold. Do not run
> `mise bootstrap` or `mise dotfiles apply` on an existing workstation until
> the migration manifest marks the applicable cutover phase ready.

## Intended scope

- macOS hosts use the official Homebrew installation and the XDG-discovered
  `src/config/homebrew/Brewfile`.
- Fedora Atomic hosts use reviewed RPM repositories and exact rpm-ostree
  overlay manifests.
- Fedora desktop applications use user-scoped Flatpaks unless an application
  specifically requires another channel.
- Toolbox, containers, Apple container machines, and WSL receive development
  configuration without desktop or host-service provisioning.
- Language runtimes and native language managers are project concerns. The
  initial global mise configuration installs none.
- Configuration follows XDG locations wherever the application supports them.

## Layout

```text
.
├── AGENTS.md
├── mise.toml
├── docs/
│   ├── architecture.md
│   ├── bootstrap.md
│   ├── doctor.md
│   ├── editors.md
│   ├── git.md
│   ├── ghostty.md
│   ├── hosts.md
│   ├── migration-manifest.md
│   ├── shell.md
│   └── ssh.md
├── host/
│   ├── apple-container/
│   ├── container/
│   ├── fedora-atomic/
│   ├── fonts/
│   ├── macos/
│   ├── toolbox/
│   └── wsl/
├── scripts/
│   ├── dotfiles-doctor
│   ├── dotfiles-status
│   └── lib/
└── src/
    └── config/             # source for ~/.config via mise symlink-each
```

`src/config/` deliberately mirrors the contents of `$XDG_CONFIG_HOME`, not the
repository root. Mise maps it explicitly to `~/.config` using `symlink-each`,
which allows local and application-owned files to coexist.

There are currently no managed files at the root of `$HOME`. If one is ever
needed, its source will live under `src/home/` and receive an explicit
`[dotfiles]` entry. Shell bootstrap is expected to use a managed block inside
the locally owned `~/.zshenv`, not a whole-file link.

## Current status

The repository contains architecture, inventory, staged zsh, Git, Ghostty,
Zed, and Neovim ports, an SSH retirement plan, candidate host manifests, and
read-only `status`/`doctor` tasks. The public configuration sources have been
validated without being applied to the workstation. VS Code and BBEdit remain
application-owned. Package and application manifests are review inputs only;
global tools and bootstrap actions remain disabled.

Before mise is installed, diagnostics run directly:

```sh
./scripts/dotfiles-status
./scripts/dotfiles-doctor
```

After mise is installed, use `mise run status` and `mise run doctor`. See
[status and doctor](docs/doctor.md) for output, safety, strict-mode, and
environment-detection details.

See [the migration manifest](docs/migration-manifest.md) for the audited legacy
state and the ordered cutover plan. See [the shell design](docs/shell.md) and
[Git design](docs/git.md) for their ownership and local override behavior.
See [editor configuration](docs/editors.md) for project tooling and private
state boundaries. See [host policy](docs/hosts.md) before changing or applying
any package, application, service, or font manifest. See
[Ghostty configuration](docs/ghostty.md) for terminal portability and local
override behavior. See [SSH configuration](docs/ssh.md) for the local-only
policy and Tailscale/recovery boundary.
