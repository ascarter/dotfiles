# dotfiles
My macOS and Linux dotfiles

The dotfiles configuration works for macOS and Ubuntu/Pop Linux including WSL.
It is untested with other Linux distributions but should work with any reasonable POSIX OS.

## Layout

Path    | Description
------  | -----------
home    | Files to be symlinked to user's home directory
scripts | Scripts for setting up different environments
themes  | Useful themes

## Requirements

The following are the minimum requirements for dotfiles to work:

* [git](https://git-scm.com/download/linux)
* zsh

On macOS, [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) is expected to be installed and configured.

## Install

```zsh
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dotfiles/main/install.sh)"
```

### Alternate Install

If directly executing script is not desired, clone into a location (recommend `~/.config/dotfiles`)

```sh
git clone git@github.com:ascarter/dotfiles.git ~/.config/dotfiles
cd ~/.config/dotfiles
./install.sh
```

### Uninstall

Run the uninstall script to remove the symlinks and restore any original files:

```sh
cd ~/.config/dotfiles
./uninstall.sh
```
