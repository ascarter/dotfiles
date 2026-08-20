# dotfiles

Portable, XDG-based development configuration managed by
[mise](https://mise.jdx.dev/). Tested on macOS and Fedora Atomic Linux.

## Bootstrap

The host must provide `curl`, `git`, and `/bin/zsh`.

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

Personal Git setup and workstation applications are intentionally excluded
from the default bootstrap. Run the optional workstation task from the
checkout when needed:

```sh
mise run bootstrap:workstation
```

The task configures Git and Git LFS, then runs the
`bootstrap:install:<name>` tasks for the workstation applications.

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
