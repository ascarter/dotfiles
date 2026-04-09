# Host Bootstrap

Each supported platform has a bootstrap script in `host/<platform>/bootstrap.sh`.
All scripts source `lib/logging.sh` for logging, guard on the expected OS, and
finish by running `gh tool install` if gh-tool is available.

Run bootstrap with:

```sh
dotfiles host init            # auto-detects platform
dotfiles host init <platform> # explicit override
```

---

## macOS (`host/macos/`)

**Files:**

| File | Purpose |
|------|---------|
| `bootstrap.sh` | Main provisioning script |
| `defaults.sh` | macOS system preferences (`defaults write`) |
| `Brewfile` | Homebrew bundle manifest |

**Bootstrap sequence:**

1. **Xcode Command Line Tools** — installs if `/Library/Developer/CommandLineTools` is missing; waits for interactive confirmation.
2. **Developer mode** — enables `spctl developer-mode` for terminal.
3. **macOS defaults** — runs `defaults.sh` to apply system preferences (Terminal focus-follows-mouse, menu bar settings).
4. **Homebrew** — installs to `/opt/homebrew` if absent, then runs `brew bundle` with the repo-local `Brewfile`.
5. **gh-tool** — `gh` is installed via Homebrew (declared in the `Brewfile`). Runs `gh tool install` to install all declared CLI tools.

**Brewfile contents** include host utilities (age, btop, sqlite, uutils-coreutils), security tools (gnupg, ykman), macOS casks (Ghostty, VS Code, Claude, etc.), and the `gh` formula itself.

---

## Fedora Atomic (`host/fedora-atomic/`)

**Files:**

| File | Purpose |
|------|---------|
| `bootstrap.sh` | Main provisioning script |
| `overlay-packages.txt` | rpm-ostree overlay manifest |

**Bootstrap sequence:**

1. **rpm-ostree upgrade** — pulls latest OS updates.
2. **Overlay packages** — reads `overlay-packages.txt` and installs each package with `rpm-ostree install --idempotent`. The overlay list is intentionally minimal:
   - `git` — bootstrap prerequisite
   - `zsh` — login shell
   - `bolt` — Thunderbolt device management
   - `solaar` — Logitech device manager
   - `steam-devices` — Steam controller udev rules
3. **Desktop-specific tweaks** — if `$XDG_CURRENT_DESKTOP` is GNOME, installs `gnome-tweaks` and applies window button layout.
4. **gh-tool** — `gh` must be installed separately (not available via rpm-ostree). Runs `gh tool install` if found on PATH.

**Note:** rpm-ostree changes require a reboot. The script logs a reminder at completion.

---

## Toolbox (`host/toolbox/`)

**Files:**

| File | Purpose |
|------|---------|
| `bootstrap.sh` | Main provisioning script |
| `dnf-packages.txt` | dnf package manifest |

**Bootstrap sequence:**

1. **Guard** — verifies `/run/.toolboxenv` exists (only present inside toolbox containers).
2. **dnf packages** — reads `dnf-packages.txt` and batch-installs with `sudo dnf install -y`:
   - `git` — version control
   - `zsh` — shell
   - `curl` — HTTP client
3. **Login shell** — sets zsh as the login shell via `chsh` if not already configured.
4. **gh-tool** — `gh` must be installed separately. Runs `gh tool install` if found on PATH.

---

## Flatpak (`host/flatpak`)

A plain-text manifest of Flathub application IDs. Not executed by any bootstrap
script automatically — used as a reference for manual Flatpak installation on
Linux desktops.

---

## Common Patterns

All bootstrap scripts follow the same structure:

```bash
#!/usr/bin/env bash
set -eu
: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/../.." && pwd)}"
source "${DOTFILES_HOME}/lib/logging.sh"

# Platform guard
# Package installation
# Desktop-specific config (if applicable)
# gh tool install (if available)
```

**gh-tool installation** differs by platform:

| Platform | gh install method |
|----------|-------------------|
| macOS | Homebrew (`brew "gh"` in Brewfile) |
| Fedora Atomic | Manual install from https://cli.github.com |
| Toolbox | Manual install from https://cli.github.com |
