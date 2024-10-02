# dotfiles
Unix dotfiles

The dotfiles configuration works for macOS, Fedora, and Ubuntu/Pop Linux including WSL.
It is untested with other Linux distributions but should work with any reasonable POSIX OS or devcontainer.

The dotfiles are managed using symlinked packages. The approach is similar to [GNU Stow](https://www.gnu.org/software/stow/). `dotfiles` implements a simpliefied version of this concept.

## Command line

The `dotfiles` command can be used to manage packages. The following are the available commands:

```sh
    Usage     	dotfiles [options] <subcommand> [package]

Subcommands:
    init      	Initialize dotfiles
    install   	Install [package]
    list      	List [package]
    sync      	Sync [package]
    uninstall 	Uninstall [package]
    update    	Update [package]

Options:
    -t        	Target directory
    -v        	Verbose```
```

### init

Initialize dotfiles. This command will ensure prerequisites are installed. The command should be run after the dotfiles are cloned.

```sh
dotfiles init
```

### install

Install package. By default, all packages are installed. To install a specific package, use the package name.

```sh
dotfiles install <package>
```

### list

List package. By default, all packages are listed. To list a specific package, use the package name. It will show the package name and the status of the package.

```sh
dotfiles list <package>
```

### sync

Sync package. By default, all packages are synced. To sync a specific package, use the package name. Sync will stow the files in the package and adopt any changes. Useful if dotfiles is already installed and a package has been updated or edited locally.

```sh
dotfiles sync <package>
```

### uninstall

Uninstall package. By default, all packages are uninstalled. To uninstall a specific package, use the package name.

```sh
dotfiles uninstall <package>
```

### update

Update package. By default, all packages are updated. To update a specific package, use the package name. Update will stow the files in the package. Useful if dotfiles is already installed and a package has been updated.

```sh
dotfiles update <package>
```

## Layout

| Path     | Description                                      |
|----------|--------------------------------------------------|
| bin      | Dotfiles tools                                   |
| packages | Configuration packages (following stow approach) |
| scripts  | Scripts for setting up different environments    |
| themes   | Useful themes                                    |

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
