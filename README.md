# dotfiles

XDG-based host configuration managed by [mise](https://mise.jdx.dev/).
Tested on macOS and Fedora Atomic Linux.

## Bootstrap

Bootstrap is intended for a clean host. The repository becomes mise's global
configuration checkout at `$MISE_CONFIG_DIR`, normally `~/.config/mise`.

### Prerequisites

Bootstrap requires `curl` and `git`.

<details>
<summary>Fedora Atomic</summary>

Update the initial deployment and install the bootstrap prerequisites before
running the script. Installer images can be behind the current RPM
repositories.

```sh
rpm-ostree upgrade
rpm-ostree install --idempotent curl git zsh
systemctl reboot
```

</details>

<details>
<summary>macOS</summary>

```sh
xcode-select --install
```

After the installer completes, open a new terminal session before continuing.

</details>

### Install

```sh
curl -fsSL https://raw.githubusercontent.com/ascarter/dotfiles/main/bootstrap.sh | sh
```

The wrapper:

* installs or updates mise at `$XDG_BIN_HOME/mise`, defaulting to
  `~/.local/bin/mise`;
* uses `mise bootstrap --from-git` to clone this repository directly into
  `$MISE_CONFIG_DIR`, defaulting to `~/.config/mise`;
* loads the cloned global configuration and applies the host bootstrap.

The destination must be absent, empty, or an existing checkout with the exact
configured origin. Resolving any other pre-existing configuration directory is
the user's responsibility.

After installation, rerun the wrapper from the global checkout when needed:

```sh
cd "${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}"
./bootstrap.sh
```

Arguments are forwarded to `mise bootstrap`; for example, use `--update` to
fast-forward the checkout and refresh bootstrap-managed state.

## Configuration layout

This repository is the global mise configuration rather than a project that
installs a separate global config:

* `config.toml` owns the shared host baseline, dotfile mappings, shell
  activation, login shell, and personal Git tasks.
* `config.macos.toml` supplies macOS defaults and hooks.
* `miserc.toml` enables automatic platform environments and environment-aware
  `conf.d` fragments.
* `conf.d/` divides aliases, tools, applications, and platform packages by
  concern. The Linux package fragment currently targets Fedora Atomic through
  the `rpm-ostree` package plugin.
* `tasks/` contains reusable bootstrap task scripts.
* `src/config/` mirrors `$XDG_CONFIG_HOME`; mise links each child into
  `~/.config` with `symlink-each`.

There are no explicit workstation, developer, or container profiles. macOS and
Linux fragments are selected automatically from the current platform.

Root home files remain locally owned. Mise manages a marker-delimited XDG block
in `~/.zshenv`, and the managed Zsh files under `src/config/zsh/` source local
`~/.zprofile` and `~/.zshrc` extensions.

OpenSSH configuration, authentication state, Git identity, and other private
machine state remain local and unmanaged.

## Optional setup

Configure personal Git identity and GitHub authentication explicitly:

```sh
mise run bootstrap:git
```

Related tasks are also opt-in:

```sh
mise run bootstrap:git-lfs
mise run bootstrap:gcm
mise run bootstrap:container:dns
```

Install vendor-distributed applications explicitly when wanted:

```sh
mise run bootstrap:apps
```

On Fedora Atomic, Proton application RPM overlays are also opt-in:

```sh
mise run bootstrap:apps:proton
```

## Update

Commit and push configuration changes to `main`, then update another
bootstrapped host with:

```sh
dotfiles-update
```

The alias delegates to `mise bootstrap --from-git ... --update`, which
fast-forward-pulls the global configuration checkout before reconciling the
host.

## Daily workflow

Check managed state with:

```sh
mise bootstrap status --missing
mise ls --current
```

Files managed with `symlink-each` are live links. Edit their sources in the
global checkout:

```sh
$EDITOR "$MISE_CONFIG_DIR/src/config/ghostty/config"
git -C "$MISE_CONFIG_DIR" diff --check
```

To add a non-mise dotfile, create it beneath `src/config/` at its intended XDG
path, then preview and apply the new link:

```sh
mise bootstrap dotfiles apply --dry-run
mise bootstrap dotfiles apply --yes
mise bootstrap dotfiles status --missing
```

Add a global tool only when it is required outside project environments:

```sh
mise use -g jq
mise which jq
git -C "$MISE_CONFIG_DIR" diff -- config.toml
```

`mise use -g` writes directly to the repository's `config.toml`, making the
declaration a reviewable change. Project-specific runtimes, language servers,
formatters, linters, debuggers, and build tools belong to their projects.

Reconcile the currently checked-out configuration without pulling it with:

```sh
mise bootstrap
```

Bootstrap is idempotent. Personal Git tasks update only the settings they own
and preserve unrelated private or work settings in `~/.gitconfig`.

## Uninstall

```sh
"${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}/uninstall.sh"
```

Uninstall removes configured links, the managed `~/.zshenv` block, mise tools,
and mise data. It preserves the Git checkout at `$MISE_CONFIG_DIR`, GitHub
authentication data, local Git configuration, and the current login-shell
selection.
