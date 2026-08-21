# dotfiles

Portable, XDG-based development configuration managed by
[mise](https://mise.jdx.dev/). Tested on macOS and Fedora Atomic Linux.

## Bootstrap

### Prerequisites

Bootstrap requires `curl` and Git. Install them before running the script:

```sh
# Fedora
sudo dnf install -y curl git

# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y curl git

# Arch Linux
sudo pacman -S --needed curl git

# macOS (opens the Command Line Tools installer)
xcode-select --install
```

After the macOS installer completes, open a new terminal session before
continuing.

```sh
curl -fsSL https://raw.githubusercontent.com/ascarter/dotfiles/main/bootstrap.sh | sh
```

From an existing checkout, run:

```sh
./bootstrap.sh
```

The script:

* Installs mise at `~/.local/bin/mise`
* Clones this repository into `~/.dotfiles`
* Runs mise bootstrap from the checkout

## Configuration layers

Mise loads `config.toml` as the portable baseline and automatically adds the
matching platform overlay, such as `config.macos.toml` or `config.linux.toml`.
The optional `config.workstation.toml` profile contains desktop-workstation
configuration. It is enabled only when explicitly requested, keeping the
default bootstrap suitable for WSL and Toolbox environments.

Personal Git setup and workstation applications are intentionally excluded
from the default bootstrap. To install the workstation profile on a new
machine, use one of these commands:

```sh
# From the published bootstrap script
curl -fsSL https://raw.githubusercontent.com/ascarter/dotfiles/main/bootstrap.sh | MISE_ENV=workstation sh

# From an existing checkout
MISE_ENV=workstation ./bootstrap.sh
```

To turn an existing default installation into a workstation, run this from the
checkout:

```sh
mise -E workstation bootstrap
```

The profile defines the `bootstrap` task for personal Git setup and workstation
applications, and writes a managed `env = ["workstation"]` block to
`~/.miserc.toml` so later bootstraps retain the selected profile.

## Update an existing system

Make a dotfiles change on one system, validate it, and commit and push it to
`main`. On every other bootstrapped system, propagate that change with:

```sh
dotfiles-update
```

## Daily workflow

Check the managed state:

```sh
mise bootstrap status --missing
mise ls --current
```

Files already managed with `symlink-each` are live links. Edit their source in
this repository and verify the change normally:

```sh
$EDITOR .config/ghostty/config
git diff --check
```

To add a new dotfile, create it beneath `.config/` at its intended XDG path,
then preview and apply the new link:

```sh
mise bootstrap dotfiles apply --yes
mise bootstrap dotfiles status --missing
```

Add a global tool only when it is required outside project environments:

```sh
mise use -g jq
mise which jq
git diff -- .config/mise/config.toml
```

`mise use -g` installs the tool, selects it globally, and writes
`~/.config/mise/config.toml`. That file is a managed link to
`.config/mise/config.toml`, so the declaration becomes a reviewable repository
change.

Reconcile the managed dotfiles, tools, and platform configuration at any time
with:

```sh
./bootstrap.sh
```

The bootstrap is idempotent. The optional workstation Git tasks update only
the settings they own and preserve unrelated private or work settings in
`~/.gitconfig`.

## Uninstall

```sh
./uninstall.sh
```

Uninstall removes the configured links, managed `.zshenv` block, mise tools,
and mise data. It preserves this checkout, GitHub authentication data, local
Git configuration, and the current login-shell selection.
