# dotfiles
Unix dotfiles

The dotfiles configuration tool works for macOS and Linux. It should work with any reasonable POSIX OS or devcontainer.

The dotfiles are managed using symlinks. The source file is under the `config` directory in the location where it should appear in `$HOME`.

[mise](https://github.com/jdx/mise) is used to manage development tools.
Using mise allows tools to be installed cross-platform instead of using different package managers for each OS.

## Command line

The `dotfiles` command can be used to manage the configuration. The following are the available commands:

```sh
~/.config/dotfiles % dotfiles
dotfiles  	Configuration management tool using symlinks

Usage:    	dotfiles [options] <command>

Commands:
  init    	Initialize dotfiles
  list    	Show configuration status
  adopt   	Add changed configuration files
  unlink  	Unlink configuration
  update  	Update configuration

Options:
  -d      	dotfiles directory
  -t      	Target directory
  -v      	Verbose
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

### adopt

Adopt configuration files. This command will adopt any changes and link the files from the dotfiles directory to the target directory.

```sh
dotfiles adopt
```

### unlink

Unlink the configuration files. This command will remove the symlinks created by the dotfiles tool.

```sh
dotfiles unlink
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
