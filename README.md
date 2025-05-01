# dotfiles

Unix dotfiles

The dotfiles configuration tool works for macOS and Linux.
It should work with any reasonable POSIX OS, toolbox, or devcontainer.

I run on the following platforms:

* macOS (primary)
* Fedora Cosmic Atomic
* Windows 11 WSL 2 Fedora

## Motivation

I wrote this tool to manage my dotfiles across multiple machines and operating systems.
It allows me to easily update and manage my configuration files.

I also included scripts to provsion the operating systems I use along with tools and development environments.
This tool is an attempt to make it easier to manage the local environments consistently.
I utilize [Homebrew][] to manage packages as much as possible on both
macOS and Linux (including in WSL2). Homebrew now uses OCI based Github Packages and is
implementing [SLSA sigstore attestations][SLSA]. Generally, this means secure packages
that are more up-to-date than many distros. It is also fully portable across distros
and operating systems.

[homebrew]: https://brew.sh
[SLSA]: https://openssf.org/blog/2023/11/06/alpha-omega-grant-to-help-homebrew-reach-slsa-build-level-2/?ref=ypsidanger.com

## Implementation

The dotfiles are managed using symlinks. The source files are under the `config` directory in the location where it should appear in `$HOME`.

## Requirements

The following are the minimum requirements for dotfiles to work:

- [git][]

On macOS, [Xcode][] is expected to be installed and configured.
The script `scripts/macos.sh` which will be prompted to run on install will
take care of installing Xcode.

[git]: https://git-scm.com/
[Xcode]: https://itunes.apple.com/us/app/xcode/id497799835?mt=12

## Install

The `install.sh` script will do the following:
* Clone the `dotfiles` repo to `${XDG_DATA_HOME}` if not present
* Run `dotfiles link` to symlink the config files
* Prompt to run the platform install script

```sh
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dotfiles/main/install.sh)"
```

### Alternate Install

If directly executing script is not desired, clone into a location (recommend `~/.local/share/dotfiles`)

```sh
git clone git@github.com:ascarter/dotfiles.git ~/.local/share/dotfiles
cd ~/.config/dotfiles
./install.sh
```

### Install from branch

```sh
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dotfiles/main/install.sh)" -s -- -b <branch>
```

### Uninstall

Run the uninstall script to remove the symlinks and restore any original files:

```sh
cd ~/.config/dotfiles
./uninstall.sh
```

## Layout

| Path    | Description                |
| ------- | -------------------------- |
| bin     | Dotfiles tools             |
| etc     | Shell profiles             |
| scripts | Install scripts            |
| src     | Configuration source files |

## Command line

The `dotfiles` command can be used to manage the configuration. The following are the available commands:

```sh
~/.config/dotfiles % dotfiles
dotfiles  	Configuration management tool using symlinks

Usage:    	dotfiles [options] <command>

Commands:
  shellenv  Export configuration for dotfiles
  status  	Show configuration status
  init      Init dotfiles for shells
  link    	Link configuration
  unlink  	Unlink configuration
  update    Update dotfiles
  edit      Edit dotfiles in $EDITOR

Options:
  -d      	dotfiles directory
  -t      	Target directory
  -v      	Verbose
```

### shellenv

Configure shell for dotfiles. `dotfiles init` will source in user's shell configuration

```
$ dotfiles shellenv
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export LOCAL_BIN_HOME=${LOCAL_BIN_HOME:-$HOME/.local/bin}
export DOTFILES=${DOTFILES:-$XDG_DATA_HOME/dotfiles}
export PATH=$LOCAL_BIN_HOME:$PATH
[ -f ${DOTFILES}/etc/profile ] && . ${DOTFILES}/etc/profile
```
### init

Provision dotfiles and add shellenv to profile startup scripts

*~/.bashrc*
```
# Added by `dotfiles init` on Fri Apr 18 20:59:46 PDT 2025
eval "$($HOME/.local/bin/dotfiles shellenv)"
```

*~/.zshrc*
```
# Added by `dotfiles init` on Fri Apr 18 21:03:22 PDT 2025
eval "$($HOME/.local/bin/dotfiles shellenv)"
```

### status

Show the status of the configuration files. This command will list the files that are linked, missing, or in conflict.

```sh
dotfiles status
```

### link

Link the configuration files. This command will create symlinks for all the configuration files tracked in `cfg` relative to the target directory (`$HOME` by default).

```sh
dotfiles link
```

### unlink

Unlink the configuration files. This command will remove the symlinks created by the dotfiles tool.

```sh
dotfiles unlink
```
### update

Pull latest dotfiles and verify configuration files are linked.

```sh
dotfiles update
```

## Scripts

These are convenience installer scripts for setting up the platforms I use.
The scripts are all independent and customized to how I use each platform.

The scripts are meant to be able to run independent of the dotfiles.
The scripts should all work idempotently so they are safe to run repeatedly.
This could be useful to pick up new additions or to fix broken installs.
