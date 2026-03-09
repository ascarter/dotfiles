# Repository Guidelines

## Start Here (Single Entry Point)
Use this file as the canonical contributor and agent entrypoint. Read `AGENTS.md` first, then open supporting docs from the map below as needed.

Conflict rule:
- If guidance differs between files, follow `AGENTS.md` and then update the other document to match.

## Documentation Map
- `README.md`: install/bootstrap quick start.
- `docs/dev-environment.md`: detailed lifecycle, tier model, and implementation patterns.
- `docs/tools-backlog.md`: tool status, priorities, and pending decisions.
- `.github/copilot-instructions.md`: thin pointer for coding assistants back to this file.

## Project Structure & Module Organization
- `bin/dotfiles`: primary CLI entrypoint (`init`, `shell`, `sync`, `status`, `script`, `tool`).
- `config/`: source-of-truth configs synced into `$XDG_CONFIG_HOME`.
- `lib/tool.sh`: sourced library for tool installer scripts; declares `XDG_OPT_*` vars, provides `tool_gh_install`, `tool_link`, `tool_latest_tag`, `tool_installed_tag`.
- `tools/`: flat directory of installer scripts, one per tool capability. Each sources `lib/tool.sh`.
- `host/os/<os>/`: host OS baseline provisioning (`init.sh`) and OS-local helpers.
- `host/config/`: host config synthesis (`gitconfig.sh`, `toolbox-init.sh`).
- `scripts/*.sh`: convenience orchestration scripts (for example, `scripts/developer.sh`).

## Tool Script Categories

All scripts in `tools/` are self-contained tool installers. Four patterns coexist:

1. **GitHub release tools** — source `lib/tool.sh`, call `tool_gh_install`, call `tool_link` for each binary/manpage/completion. Example: `ripgrep.sh`, `just.sh`, `fzf.sh`, `jq.sh`, `yq.sh`, `serie.sh`, `tree-sitter.sh`.
2. **Vendor curl installers** — source `lib/tool.sh` for environment, run `curl | sh`. Example: `zed.sh`, `claude.sh`.
3. **AppImage / custom URL tools** — source `lib/tool.sh`, download and place manually, may include desktop integration. Example: `ghostty.sh`.
4. **Service/package manager tools** — source `lib/tool.sh`, branch on OS/distro, call package manager. Example: `tailscale.sh`, `speedtest.sh`, `gh.sh`.

Every tool script starts with `command -v <tool>` to skip silently if already installed by any means (Homebrew, rpm-ostree, etc.).

## XDG_OPT_* Convention

`dotfiles` declares three XDG-style variables as a first-class peer of the standard XDG dirs.
They are exported by `cmd_env` and set with fallbacks by `lib/tool.sh`:

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
- `bin/dotfiles init`: run initial platform bootstrap flow.
- `bin/dotfiles shell`: wire `~/.zshenv` to `dotfiles env`.
- `bin/dotfiles sync`: symlink `config/` into `$XDG_CONFIG_HOME`.
- `bin/dotfiles tool install`: install all tools in `tools/` (requires `gh` to be installed first).
- `bin/dotfiles tool install <name>`: install a single tool by name.
- `bin/dotfiles tool uninstall [<name>]`: remove installed tool(s); preserves cache.
- `bin/dotfiles tool clean [<name>]`: clear downloaded archives from cache.
- `bin/dotfiles script tools/gh`: run a specific installer script directly.
- `./test.sh`: smoke test install/sync in `.testuser/`.

## Coding Style & Naming Conventions
- Default shell: `#!/usr/bin/env bash` with `set -eu` for all scripts.
- `lib/tool.sh` has no shebang (sourced, not executed) and does not use `set -e` internally.
- Keep scripts linear, explicit, idempotent, and re-runnable.
- Follow `.editorconfig` (2 spaces, UTF-8, LF, trailing newline).
- Name scripts by capability, not installer backend.
- Tool scripts self-locate via: `: "${DOTFILES_HOME:=$(cd "$(dirname "$0")/.." && pwd)}"`
- Use `XDG_OPT_*` vars for opt-space paths; use standard `XDG_*` vars for everything else.

## Testing Guidelines
- No unit test suite currently; validation is command/script based.
- Run `./test.sh` for bootstrap/sync changes.
- For tool script edits, run the script and verify `bin/dotfiles status`.

## Commit & Pull Request Guidelines
- Use short imperative commit subjects (for example: `Refactor Fedora gh install flow with shared host helpers`).
- Keep commits scoped to one capability or lifecycle area.
- PRs should include changed behavior, impacted platforms, and validation commands run.

## Security & Configuration Tips
- Prefer XDG paths. For opt-managed tools use `$XDG_OPT_HOME`/`$XDG_OPT_BIN`/`$XDG_OPT_SHARE`.
- Keep host installs for OS-integrated needs; prefer opt-space installs otherwise.
- `gh` must be installed before running `dotfiles tool install` (it is used by `lib/tool.sh` for GitHub releases).
