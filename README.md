# dotfiles

XDG-based workstation configuration managed by [mise](https://mise.jdx.dev/).
Tested on macOS and Fedora Atomic Linux.

## Bootstrap

### Prerequisites

Bootstrap expects these prerequisites to be installed before running the script:

* `curl`
* `git`

<details>
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

### Install

```sh
curl -fsSL https://raw.githubusercontent.com/ascarter/dotfiles/main/bootstrap.sh | sh
```

From an existing checkout, run:

```sh
./bootstrap.sh
```

### Profiles

Bootstrap is minimal by default: it applies shared dotfiles and the baseline
command-line tools, without selecting either optional profile. Select profiles
explicitly with `MISE_ENV`; multiple profiles are comma-separated and load in
order. A workstation bootstrap persists its selection in `~/.miserc.toml`.

The profiles have distinct purposes:

* `workstation` configures a Fedora Atomic or Fedora Workstation host, including
  RPM-managed host tools, Flatpak remotes, and machine-management applications.
  Do not use it in a Toolbox or other development container.
* `developer` installs developer runtimes and build prerequisites, including a
  C compiler on Fedora. Use it in a Fedora Toolbox, Apple container machine, or
  devcontainer instead of layering compilers onto a Fedora Atomic host.
* `container` is the Linux-container companion to `developer`. It gives the
  container its own `/opt/mise` binary, installs, state, and cache while using
  the shared `~/.config/mise` configuration and `~/.dotfiles` checkout. Its
  profile file enables the default in later container login shells.
  It uses full Mise activation in interactive Bash and Zsh shells
  and shim activation otherwise. The first bootstrap requires `sudo` only to
  create the container-owned `/opt/mise` root; the user-owned binary continues
  to support normal Mise self-updates.
* On macOS, install the Xcode Command Line Tools first, then use both profiles.
  macOS can cleanly serve as both the host and development environment.

<details>
<summary>Fedora Atomic / Fedora Workstation host</summary>

```sh
curl -fsSL https://raw.githubusercontent.com/ascarter/dotfiles/main/bootstrap.sh | env MISE_ENV=workstation sh
```

</details>

<details>
<summary>Fedora Toolbox / devcontainer / Apple container machine</summary>

```sh
curl -fsSL https://raw.githubusercontent.com/ascarter/dotfiles/main/bootstrap.sh | env MISE_ENV=developer,container sh
```
  
</details>

<details>
<summary>macOS host</summary>

```sh
curl -fsSL https://raw.githubusercontent.com/ascarter/dotfiles/main/bootstrap.sh | env MISE_ENV=workstation,developer sh
```

</details>

### Existing checkout

```sh
MISE_ENV=developer,container ./bootstrap.sh
MISE_ENV=workstation,developer ./bootstrap.sh
```

The first `workstation` bootstrap writes the selected host profiles to
`~/.miserc.toml`. A `container` bootstrap records the exact selected profile
list in its own `/etc/profile.d/mise-container.sh`, which overrides that
shared-home default before mise starts.

#### Fedora Toolbox

Create a Toolbox for development, enter it, and bootstrap the developer
profile from inside the container:

```sh
toolbox create developer
toolbox enter developer
curl -fsSL https://raw.githubusercontent.com/ascarter/dotfiles/main/bootstrap.sh | env MISE_ENV=developer,container sh
```

Bootstrap creates `/etc/profile.d/mise-container.sh`; subsequent logins 
select the developer profile and `/opt/mise` automatically:

```sh
toolbox enter developer
```

The container uses the same `~/.dotfiles` checkout and `~/.config/mise`
configuration as the Fedora host, but its Mise binary, installs, cache, and
state live beneath `/opt/mise`.

#### Apple container machine

On macOS, create a persistent Linux machine, then bootstrap the developer
profile inside it:

```sh
container machine create ubuntu:24.04 --name developer
container machine run -n developer
curl -fsSL https://raw.githubusercontent.com/ascarter/dotfiles/main/bootstrap.sh | env MISE_ENV=developer,container sh
```

Later sessions need no environment flags:

```sh
container machine run -n developer
```

Container machines map the macOS home directory into the guest, so the
container uses that shared checkout and mise configuration. The mise
binary and state remain under the guest's persistent `/opt/mise`. Running
bootstrap in the container applies the same shared dotfiles as running it on
the host.

The script:

* Installs mise at `~/.local/bin/mise`
* Clones this repository into `~/.dotfiles`
* Runs mise bootstrap from the checkout

## Configuration layers

The `mise/` directory is managed as `~/.config/mise`, while `config/`
is managed as the rest of `~/.config`.

`mise/config.toml` contains the baseline: repository bootstrap, dotfile
mappings, and personal Git tasks. Shell activation and the Zsh login shell are
workstation responsibilities in `mise/config.workstation.toml`.
`mise/config.macos.toml` is the macOS platform overlay.
`mise/miserc.toml` enables
automatic environment detection and environment-aware `mise/conf.d/` fragments;
those fragments divide platform packages, aliases, tools, and app tasks by
concern. The `workstation` and `developer` profiles are selected explicitly
with `MISE_ENV`. Workstation selection is persisted in the host's
`~/.miserc.toml`; Linux containers use `/etc/profile.d` override instead.

The Linux setup is currently intended for Fedora Atomic systems and uses the
`rpm-ostree` package plugin. macOS defaults and the focused macOS application
set load automatically on macOS.

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

Install vendor-distributed developer applications explicitly when wanted:

```sh
mise run bootstrap:apps
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
$EDITOR config/ghostty/config
git diff --check
```

then preview and apply the new link:
To add a new non-mise dotfile, create it beneath `config/` at its intended XDG
path. New files beneath `mise/` are managed as `~/.config/mise`. Then preview
and apply the new links:

```sh
mise bootstrap dotfiles apply --yes
mise bootstrap dotfiles status --missing
```

Add a baseline global tool only when it is required outside project
environments. Developer-only tools belong in the `developer` profile:

```sh
mise use -g jq
mise which jq
git diff -- mise/config.toml
```

`mise use -g` installs the tool, selects it globally, and writes
`~/.config/mise/config.toml`. That file is a managed link to `mise/config.toml`,
so the declaration becomes a reviewable repository change.

Reconcile the managed dotfiles, tools, and platform configuration at any time
with:

```sh
./bootstrap.sh
```

The bootstrap is idempotent. The Git tasks update only the settings they own and
preserve unrelated private or work settings in `~/.gitconfig`.

## Uninstall

```sh
./uninstall.sh
```

Uninstall removes the configured links, managed `.zshenv` block, mise tools,
and mise data. It preserves this checkout, GitHub authentication data, local
Git configuration, and the current login-shell selection.
