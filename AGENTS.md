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
- `bin/dotfiles`: primary CLI entrypoint (`init`, `shell`, `sync`, `status`, `script`).
- `config/`: source-of-truth configs synced into `$XDG_CONFIG_HOME`.
- `scripts/host/os/`: host OS baseline provisioning.
- `scripts/host/pkg/`: host package backend/bootstrap.
- `scripts/host/config/`: host config synthesis.
- `scripts/tools/`: one installer per capability (`gh`, `tailscale`, `vscode`, `zed`, etc.).
- `scripts/meta/`: reserved for profile orchestrators; currently deferred.

## Build, Test, and Development Commands
- `./install.sh`: bootstrap repository to `$XDG_DATA_HOME/dotfiles`.
- `bin/dotfiles init`: run initial platform bootstrap flow.
- `bin/dotfiles shell`: wire `~/.zshenv` to `dotfiles env`.
- `bin/dotfiles sync`: symlink `config/` into `$XDG_CONFIG_HOME`.
- `bin/dotfiles script tools/gh`: run a specific installer script.
- `./test.sh`: smoke test install/sync in `.testuser/`.

## Coding Style & Naming Conventions
- Default shell: POSIX `sh` with `set -eu`; use Bash only when required.
- Keep scripts linear, explicit, idempotent, and re-runnable.
- Follow `.editorconfig` (2 spaces, UTF-8, LF, trailing newline).
- Name scripts by capability, not installer backend.

## Testing Guidelines
- No unit test suite currently; validation is command/script based.
- Run `./test.sh` for bootstrap/sync changes.
- For tool script edits, run the script and verify `bin/dotfiles status`.

## Commit & Pull Request Guidelines
- Use short imperative commit subjects (for example: `Refactor Fedora gh install flow with shared host helpers`).
- Keep commits scoped to one capability or lifecycle area.
- PRs should include changed behavior, impacted platforms, and validation commands run.

## Security & Configuration Tips
- Prefer XDG paths (`$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, `$XDG_BIN_HOME`).
- Keep host installs for OS-integrated needs; prefer user-local installs otherwise.
