# dotfiles

Portable, XDG-based development configuration managed by
[mise](https://mise.jdx.dev/). Tested on macOS and Fedora Atomic Linux.

## Bootstrap

### Prerequisites

Bootstrap expects these prerequisites to be installed before running the script:

* `curl`
* `git`

<details open>
<summary>Fedora Atomic</summary>

On a newly installed system, update the initial deployment and reboot before
bootstrap. The installer image can be behind the current RPM repositories.

```sh
rpm-ostree upgrade
rpm-ostree install --idempotent curl git zsh
systemctl reboot
```

</details>

<details>
<summary>Fedora Workstation</summary>

```sh
sudo dnf upgrade --refresh
sudo dnf install -y curl git
```

</details>

<details>
<summary>Ubuntu or Debian</summary>

```sh
sudo apt-get update && sudo apt-get install -y curl git
```

</details>

<details>
<summary>Arch Linux</summary>

```sh
sudo pacman -S --needed curl git
```

</details>

<details>
<summary>macOS</summary>

```sh
xcode-select --install
```

macOS includes Zsh. After the installer completes, open a new terminal session
before continuing.

</details>


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

Mise loads `config.toml` as the portable baseline and configuration fragments
from `conf.d/` for active environments. The optional
`config.workstation.toml` profile contains desktop-workstation configuration.
It is enabled only when explicitly requested, keeping the default bootstrap
suitable for WSL and Toolbox environments. On Fedora, its managed profile
block also enables the `fedora` environment, which loads the Fedora-specific
configuration and package fragments.

Personal Git setup and workstation applications are intentionally excluded
from the default bootstrap. The workstation profile configures Zsh as the login
shell after the documented prerequisites are installed; on Fedora, it also
declares Zsh for the appropriate package manager. To install the workstation
profile on a new machine, use one of these commands:

### From the published bootstrap script
```sh
curl -fsSL https://raw.githubusercontent.com/ascarter/dotfiles/main/bootstrap.sh | MISE_ENV=workstation sh
```

### From an existing checkout
```
MISE_ENV=workstation ./bootstrap.sh
```

### Convert an existing default installation into a workstation
To turn an existing default installation into a workstation, run this from the
checkout:

```sh
mise run bootstrap:workstation
```

The profile defines the `bootstrap` task for workstation applications and the
login shell, and writes a managed environment block to `~/.miserc.toml` so
later bootstraps retain the selected profile. The block is
`env = ["workstation", "fedora"]` on Fedora and `env = ["workstation"]`
elsewhere.

Configure personal Git identity and GitHub authentication explicitly when needed:

```sh
mise run bootstrap:git
```

The related personal Git and development-environment tasks are also opt-in:

```sh
mise run bootstrap:git-lfs
mise run bootstrap:gcm
mise run bootstrap:container:dns
```

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
