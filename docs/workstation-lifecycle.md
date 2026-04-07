# Workstation Lifecycle

Day-to-day operations for managing your workstation with dotfiles.

---

## First Bootstrap (From Zero)

```sh
# 1. Clone and initialize
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dotfiles/main/install.sh)"

# 2. Provision the host OS
dotfiles host init

# 3. Reboot if on Fedora Atomic (rpm-ostree requires restart)
# 4. Reload shell to pick up environment changes

# 5. Configure git identity
dotfiles gitconfig

# 6. Authenticate
gh auth login
```

After bootstrap, `dotfiles doctor` should report all checks passing.

---

## Daily Maintenance

Use native tools directly — there are no dotfiles wrappers for package updates.

```sh
# macOS
brew update && brew upgrade

# aqua (all platforms)
aqua update
aqua i -a

# Language toolchains
rustup update
uv self update
fnm install --lts
```

---

## Repo Update

Pull the latest dotfiles and re-sync config:

```sh
dotfiles update    # git pull --ff-only + unlink + sync
```

Or manually:

```sh
cd "$DOTFILES_HOME"
git pull
dotfiles sync
```

---

## Health Check

```sh
dotfiles doctor
```

Checks XDG directories, `.zshenv` bootstrap line, config sync status, aqua
availability, and platform prerequisites (Homebrew on macOS). Returns non-zero
if any check fails.

---

## Common Tasks

### Adding a CLI tool

Add the tool to the appropriate aqua import file in `config/aquaproj-aqua/imports/`:

| Import file | Category |
|------------|----------|
| `core.yaml` | Portable CLI tools (ripgrep, jq, fzf, etc.) |
| `editors.yaml` | Editor-related tools |
| `languages.yaml` | Language toolchain tools |
| `agents.yaml` | AI/agent CLI tools |

Then install:

```sh
aqua i -a
```

### Adding a host package

Edit the platform-specific manifest:

| Platform | File | Command |
|----------|------|---------|
| macOS | `host/macos/Brewfile` | `brew bundle --file host/macos/Brewfile install` |
| Fedora Atomic | `host/fedora-atomic/overlay-packages.txt` | `rpm-ostree install <package>` |
| Toolbox | `host/toolbox/dnf-packages.txt` | `sudo dnf install <package>` |

### Adding config

Drop files into `config/` mirroring the `$XDG_CONFIG_HOME` layout, then sync:

```sh
dotfiles sync
```

Config sync creates symlinks from `$XDG_CONFIG_HOME` pointing back to the
repo. Use `dotfiles status` to verify.

### Provisioning a new toolbox container

```sh
dotfiles init
dotfiles host init    # auto-detected as toolbox via /run/.toolboxenv
```

### Checking workstation status

```sh
dotfiles status       # config symlink drift
dotfiles host status  # detected platform, hostname, OS info
dotfiles doctor       # full health check
```

---

## Validation

After any significant change, verify the environment:

```sh
dotfiles doctor
dotfiles status
dotfiles host status
```
