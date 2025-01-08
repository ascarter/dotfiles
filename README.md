# dotfiles
Unix dotfiles

The dotfiles configuration tool works for macOS and Linux. It should work with any reasonable POSIX OS or devcontainer.

The dotfiles are managed using symlinks. The source file is under the `config` directory in the location where it should appear in `$HOME`.

## Command line

The `dotfiles` command can be used to manage the configuration. The following are the available commands:

```sh
    Usage     	dotfiles [options] <subcommand>

Subcommands:
    init      	Initialize dotfiles
    status    	Show configuration status
    sync      	Sync configuration
    uninstall 	Uninstall configuration
    update    	Update configuration

Options:
    -d        	Dotfiles directory
    -t        	Target directory
    -v        	Verbose
```

### init

Initialize dotfiles. This command will ensure prerequisites are installed and link the configuration files. The command should be run after the dotfiles are cloned.

```sh
dotfiles init
```

### status

Show the status of the configuration files. This command will list the files that are linked, missing, or in conflict.

```sh
dotfiles status
```

### sync

Sync the configuration files. This command will adopt any changes and link the files from the dotfiles directory to the target directory.

```sh
dotfiles sync
```

### uninstall

Uninstall the configuration files. This command will remove the symlinks created by the dotfiles tool.

```sh
dotfiles uninstall
```

### update

Update the configuration files. This command will pull the latest changes from the dotfiles repository and link the files.

```sh
dotfiles update
```

## Layout

| Path     | Description                  |
|----------|------------------------------|
| bin      | Dotfiles tools               |
| config   | Configuration source files   |
| packages | Install scripts for packages |
| themes   | Useful themes                |

## Requirements

The following are the minimum requirements for dotfiles to work:

* [git](https://git-scm.com/download/linux)

On macOS, [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) is expected to be installed and configured.

## Install

```sh
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dotfiles/main/install.sh)"
```

### Alternate Install

If directly executing script is not desired, clone into a location (recommend `~/.config/dotfiles`)

```sh
git clone git@github.com:ascarter/dotfiles.git ~/.config/dotfiles
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
