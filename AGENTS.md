# Repository Guidelines

## Start Here (Single Entry Point)
Use this file as the canonical contributor and agent entrypoint. Read `AGENTS.md` first, then open supporting docs from the map below as needed.

Conflict rule:
- If guidance differs between files, follow `AGENTS.md` and then update the other document to match.

## Documentation Map
- `README.md`: install/bootstrap quick start.
- `docs/dev-environment.md`: detailed lifecycle, tier model, and implementation patterns.
- `.github/copilot-instructions.md`: thin pointer for coding assistants back to this file.

## Project Structure & Module Organization
- `bin/dotfiles`: primary CLI entrypoint (`init`, `shell`, `env`, `sync`, `status`, `update`, `edit`, `host`, `tool`, `gitconfig`, `script`).
- `config/`: source-of-truth configs synced into `$XDG_CONFIG_HOME`.
- `lib/core.sh`: sourced library; tty/logging functions (`log`, `warn`, `error`, `abort`, `ensure`, `success`).
- `lib/sync.sh`: sourced library; `_sync` implementation for link/unlink/status modes.
- `lib/tool.sh`: sourced library; `dotfiles tool` subcommand implementation (`_tool_cmd` and helpers).
- `lib/opt.sh`: sourced installer library; declares `XDG_OPT_*` vars, provides `tool_gh_install`, `tool_link`, `tool_latest_tag`, `tool_installed_tag`.
- `lib/os/fedora/pkg.sh`: Fedora package management helper (dnf/rpm-ostree); called by tool scripts.
- `lib/os/fedora/repo.sh`: Fedora repo management helper; called by tool scripts.
- `tools/`: flat directory of installer scripts, one per tool capability. Each sources `lib/opt.sh`.
- `host/<platform>.sh`: OS baseline provisioning; one script per environment (`macos.sh`, `fedora.sh`, `toolbox.sh`).
- `scripts/*.sh`: convenience and orchestration scripts (e.g. `gitconfig.sh`, `developer.sh`).

## Tool Script Categories

All scripts in `tools/` are self-contained tool installers. Four patterns coexist:

1. **GitHub release tools** — source `lib/opt.sh`, call `tool_gh_install`, call `tool_link` for each binary/manpage/completion. Example: `ripgrep.sh`, `just.sh`, `fzf.sh`, `jq.sh`, `yq.sh`, `serie.sh`, `tree-sitter.sh`.
2. **Vendor curl installers** — source `lib/opt.sh` for environment, run `curl | sh`. Example: `zed.sh`, `claude.sh`.
3. **AppImage / custom URL tools** — source `lib/opt.sh`, download and place manually, may include desktop integration. Example: `ghostty.sh`.
4. **Service/package manager tools** — source `lib/opt.sh`, branch on OS/distro, call package manager. Example: `tailscale.sh`, `speedtest.sh`, `gh.sh`.

Every tool script starts with `command -v <tool>` to skip silently if already installed by any means (Homebrew, rpm-ostree, etc.).

## XDG_OPT_* Convention

`dotfiles` declares three XDG-style variables as a first-class peer of the standard XDG dirs.
They are exported by `cmd_env` and set with fallbacks by `lib/opt.sh`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `XDG_OPT_HOME` | `~/.local/opt` | Root for opt-managed tool installations |
| `XDG_OPT_BIN` | `$XDG_OPT_HOME/bin` | Symlink farm for binaries (on PATH) |
| `XDG_OPT_SHARE` | `$XDG_OPT_HOME/share` | Symlink farm for man pages and completions (on MANPATH) |

`XDG_OPT_BIN` is prepended to `PATH`; `XDG_OPT_SHARE/man` is prepended to `MANPATH`.

## Tool Storage Layout

```
~/.local/opt/                   XDG_OPT_HOME
  bin/                          XDG_OPT_BIN   — symlinks to installed binaries
  share/                        XDG_OPT_SHARE — symlinks to man pages, completions
  cellar/                       TOOLS_CELLAR  — versioned extracted assets
    <name>/
      <tag>/

~/.cache/tools/                 TOOLS_CACHE   — downloaded archives
  <name>/

~/.local/state/tools/           TOOLS_STATE   — installed version receipts
  <name>                        one file per tool, contains the installed tag
```

`XDG_OPT_HOME` is self-contained: `rm -rf ~/.local/opt` removes all opt-managed tools
and their symlinks. Cache and state are separate and survive an uninstall.

## Build, Test, and Development Commands
- `./install.sh`: bootstrap repository to `$XDG_DATA_HOME/dotfiles`.
- `bin/dotfiles init`: set up XDG dirs, wire shell, and sync config.
- `bin/dotfiles host init`: run OS baseline provisioning (auto-detects `macos`, `fedora`, `toolbox`).
- `bin/dotfiles host status`: show detected host environment info.
- `bin/dotfiles gitconfig`: generate machine-specific `~/.gitconfig`.
- `bin/dotfiles sync`: symlink `config/` into `$XDG_CONFIG_HOME`.
- `bin/dotfiles tool install`: install all tools in `tools/` (requires `gh` to be installed first).
- `bin/dotfiles tool install <name>`: install a single tool by name.
- `bin/dotfiles tool uninstall [<name>]`: remove installed tool(s); preserves cache.
- `bin/dotfiles tool clean [<name>]`: clear downloaded archives from cache.
- `bin/dotfiles script <name>`: run a script from `scripts/` directly.
- `./test.sh`: smoke test install/sync in `.testuser/`.

## Coding Style & Naming Conventions
- Default shell: `#!/usr/bin/env bash` with `set -eu` for all scripts.
- Sourced libraries (`lib/*.sh`) have no shebang and do not use `set -e` internally.
- Keep scripts linear, explicit, idempotent, and re-runnable.
- Follow `.editorconfig` (2 spaces, UTF-8, LF, trailing newline).
- Name scripts by capability, not installer backend.
- Tool scripts self-locate via: `: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"`
- Host scripts self-locate one level deeper: `$(dirname "$0")/..` from `host/`.
- Use `XDG_OPT_*` vars for opt-space paths; use standard `XDG_*` vars for everything else.

## Testing Guidelines
- No unit test suite currently; validation is command/script based.
- Run `./test.sh` for bootstrap/sync changes.
- For tool script edits, run the script and verify `bin/dotfiles status`.

## Commit & Pull Request Guidelines
- Use short imperative commit subjects (for example: `Add dotfiles host status subcommand`).
- Keep commits scoped to one capability or lifecycle area.
- PRs should include changed behavior, impacted platforms, and validation commands run.

## Security & Configuration Tips
- Prefer XDG paths. For opt-managed tools use `$XDG_OPT_HOME`/`$XDG_OPT_BIN`/`$XDG_OPT_SHARE`.
- Keep host installs for OS-integrated needs; prefer opt-space installs otherwise.
- `gh` must be installed before running `dotfiles tool install` (used by `lib/opt.sh` for GitHub releases).
