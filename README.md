# dotfiles

Unix dotfiles

The dotfiles configuration tool works for macOS and Linux.
It should work with any reasonable POSIX OS or devcontainer.

## Motivation

I wrote this tool to manage my dotfiles across multiple machines and operating systems.
It allows me to easily update and manage my configuration files.

I also included scripts to provsion the operating systems I use along with tools and development environments.
This tool is an attempt to make it easier to manage the local environments consistently.

## Implementation

The dotfiles are managed using symlinks. The source file is under the `config` directory in the location where it should appear in `$HOME`.

It is well tested on macOS. I also use Fedora Silverblue as a second environment.

## Requirements

The following are the minimum requirements for dotfiles to work:

- [git](https://git-scm.com/download/linux)

On macOS, [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) is expected to be installed and configured.
The script `scripts/os/macos.sh` which will be prompted to run on install will
take care of installing Xcode.

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
| cfg     | Configuration source files |
| scripts | Install scripts            |

## Command line

The `dotfiles` command can be used to manage the configuration. The following are the available commands:

```sh
~/.config/dotfiles % dotfiles
dotfiles  	Configuration management tool using symlinks

Usage:    	dotfiles [options] <command>

Commands:
  status  	Show configuration status
  link    	Link configuration
  unlink  	Unlink configuration
  update    Update dotfiles

Options:
  -d      	dotfiles directory
  -t      	Target directory
  -v      	Verbose
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

| Script                   | Description                           |
| ------------------------ | ------------------------------------- |
| scripts/*.sh             | Install script for developer tools    |
| scripts/os/*.sh          | Install script for each platform      |
