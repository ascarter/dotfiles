# Tooling Implementation Backlog

This backlog tracks implementation progress for development tools across Linux and macOS, aligned with:

- `AGENTS.md` (tiering + script taxonomy policy)
- `docs/dev-environment.md` (lifecycle + provisioning model)

---

## Status Legend

- `todo` — not started
- `in-progress` — currently being implemented
- `blocked` — waiting on decision/dependency
- `done` — implemented and validated

---

## Tier Legend

- `host` — OS-integrated, system-level
- `layered` — toolbox/container base layer
- `local-xdg` — user-local in XDG directories
- `project` — per-project/per-toolbox

---

## Foundations Implemented (Completed)

The following baseline platform work is complete:

- Script taxonomy refactor is in place:
  - `scripts/host/os/`
  - `scripts/host/pkg/`
  - `scripts/host/config/`
  - `scripts/tools/`
- `dotfiles script` now resolves script paths recursively relative to `scripts/`
- `dotfiles init` uses canonical script paths:
  - `host/os/<platform>`
  - `host/pkg/homebrew`
  - `host/config/gitconfig`
- `dotfiles shell` command added as the single shell bootstrap entrypoint:
  - ensures `~/.zshenv` dotfiles env bootstrap line
  - sets login shell to detected zsh path (Linux, when available)
- Fedora Atomic host provisioning now idempotently requests:
  - `rpm-ostree install --idempotent git`
  - `rpm-ostree install --idempotent zsh`
- Toolbox bootstrap script added:
  - `scripts/host/config/toolbox-init.sh`
  - uses container existence check via `podman container exists`
  - performs container-local package baseline (optional)
  - runs `dotfiles shell` + `dotfiles sync`
  - avoids host provisioning logic inside toolbox

---

## Backlog Table

| Tool / Capability | Status | Target Tier | Platform Scope | Install Source/Method | Script Path (planned/current) | Acceptance Checks |
|---|---|---|---|---|---|---|
| `git` | in-progress | host | linux, macos | OS package manager / host provisioning | current: `scripts/host/os/fedora.sh`, `scripts/host/os/macos.sh` | `command -v git`; clone/pull works |
| `gh` | todo | local-xdg (optional host/layered) | linux, macos | package/binary installer | planned: `scripts/tools/gh.sh` | `gh --version`; `gh auth status`; `gh auth setup-git` works |
| `git-credential-manager` | in-progress | host (conditional) | macos (work), optional linux | native package/vendor install | planned: `scripts/host/config/git-credential-manager.sh` | `command -v git-credential-manager` (where required); Azure DevOps HTTPS auth/token flow works |
| `helix` (`hx`) | todo | local-xdg (optional layered) | linux, macos | binary/package | planned: `scripts/tools/helix.sh` | `hx --version`; reads config from `$XDG_CONFIG_HOME/helix` |
| `ripgrep` (`rg`) | blocked | layered | linux (+ macos fallback) | image/base package manager | image definition / host pkg policy | `rg --version`; available in host + toolbox |
| `serie` | todo | local-xdg | linux, macos | package/binary | planned: `scripts/tools/serie.sh` | `serie --version` |
| `jq` | blocked | layered | linux (+ macos fallback) | image/base package manager | image definition / host pkg policy | `jq --version`; parse smoke test |
| `yq` | blocked | layered | linux (+ macos fallback) | image/base package manager | image definition / host pkg policy | `yq --version`; parse smoke test |
| `fnm` | in-progress | local-xdg | linux, macos | user-local installer | existing shell init + planned `scripts/tools/fnm.sh` | `fnm --version`; `fnm install --lts`; `node -v` in new shell |
| `go` | in-progress | local-xdg | linux, macos | user-managed toolchain | planned: `scripts/tools/go.sh` | `go version`; XDG-aligned `go env` values |
| `just` | blocked | layered (optional local) | linux (+ macos fallback) | image/base package manager | image definition / host pkg policy | `just --version`; recipe executes |
| `rustup` | in-progress | local-xdg | linux, macos | rustup installer | planned: `scripts/tools/rustup.sh` | `rustup show`; `cargo --version`; XDG paths |
| `rv` | blocked | local-xdg | linux, macos | tool-specific installer | planned: `scripts/tools/rv.sh` | `rv --version`; integration verified |
| `uv` | in-progress | local-xdg | linux, macos | user-local installer | planned: `scripts/tools/uv.sh` | `uv --version`; `uv tool install` works |
| `copilot-cli` | todo | local-xdg | linux, macos | vendor/package installer | planned: `scripts/tools/copilot-cli.sh` | CLI runs; auth succeeds |
| `codex` | todo | local-xdg | linux, macos | vendor/package installer | planned: `scripts/tools/codex.sh` | CLI runs; auth succeeds |
| `claude code` | todo | local-xdg | linux, macos | vendor/package installer | planned: `scripts/tools/claude-code.sh` | CLI runs; auth succeeds |
| `open code` | blocked | local-xdg | linux, macos | vendor/package installer | planned: `scripts/tools/open-code.sh` | CLI runs; package/source decision documented |
| `vscode` | in-progress | local-xdg (linux), host/brew (macos optional) | linux, macos | custom installer + cask fallback | current: `scripts/tools/vscode.sh` | `code --version`; desktop entry/launch works |
| `zed` | in-progress | local-xdg | linux, macos | vendor installer/script | current: `scripts/tools/zed.sh` | binary present; deterministic reinstall behavior |
| `ghostty` | in-progress | host capability (provider varies) | linux, macos | linux appimage/user-local, macos cask | current: `scripts/tools/ghostty.sh` | binary launches; desktop/app registration works |
| `tailscale` | in-progress | host capability | linux, macos | distro/cask package + service | current: `scripts/tools/tailscale.sh` | `tailscale version`; service/login flow works |
| `speedtest` | todo | tools/apps profile | linux, macos | package repository/package manager | current: `scripts/tools/speedtest.sh` (needs rewrite) | `speedtest --version`; smoke test succeeds |
| `proton*` | in-progress | apps profile | linux (fedora-focused), macos via casks | rpm/dnf/rpm-ostree + cask equivalents | current: `scripts/tools/proton.sh` | installs/updates are idempotent |

---

## Revised Priorities

## P0 — Git and Shell Foundation (Current Focus)

1. Document and validate conditional `git-credential-manager` usage (required for macOS work/Azure DevOps, optional for personal Linux)
2. Harden `gitconfig` auth/signing workflow for deterministic runs
3. Validate `gh` + git helper integration across host and toolbox
4. Validate `dotfiles shell` behavior in:
   - host login sessions
   - toolbox bootstrap sessions

## P1 — Language & Runtime Managers

1. `fnm` scripted install + default Node bootstrap
2. `rustup` scripted install with XDG-aligned paths
3. `uv` scripted install + workflow validation
4. `go` local toolchain install/update strategy
5. Clarify `rv` role and integration path

## P2 — Baseline CLI Completeness

1. Finalize layered baseline list (`rg`, `jq`, `yq`, `just`, optional `gh`)
2. Define macOS fallback behavior for layered-oriented tools
3. Add baseline CLI validation script/checklist

## P3 — AI CLI Suite

1. Implement installers for `copilot-cli`, `codex`, `claude code`, `open code`
2. Standardize auth/bootstrap guidance
3. Ensure binaries resolve from intended tier/path

## P4 — Desktop/App Script Hardening

1. Rewrite/fix `speedtest.sh`
2. Harden `zed.sh` for deterministic install/update
3. Improve `tailscale.sh` service/login separation and idempotence
4. Keep `ghostty.sh` and `vscode.sh` update-safe and repeatable

---

## Decisions Needed (Open)

| Decision | Needed For | Owner | Due | Notes |
|---|---|---|---|---|
| Canonical `rv` source and purpose | `rv` integration | you | tbd | Confirm exact runtime manager role |
| Canonical package/source for `open code` | installer script | you | tbd | Resolve naming/package ambiguity |
| Layered baseline package list finalization | `rg`, `jq`, `yq`, `just`, optional `gh` | you | tbd | Needed before image automation |
| `git-credential-manager` scope decision | host credential policy | you | tbd | Keep conditional: required for macOS work/Azure DevOps, optional for personal Linux |
| macOS policy for Homebrew vs local-xdg per tool | consistency strategy | you | tbd | Can remain capability-based |
| AI CLI auth workflow policy | copilot/codex/claude/open | you | tbd | interactive vs scripted guidance |

---

## Script Work Queue (Planned)

1. `scripts/tools/gh.sh`
2. `scripts/host/config/git-credential-manager.sh` (conditional path; prioritize macOS work setup)
3. `scripts/tools/fnm.sh`
4. `scripts/tools/rustup.sh`
5. `scripts/tools/uv.sh`
6. `scripts/tools/go.sh`
7. `scripts/tools/copilot-cli.sh`
8. `scripts/tools/codex.sh`
9. `scripts/tools/claude-code.sh`
10. `scripts/tools/open-code.sh`
11. `scripts/tools/speedtest.sh` (rewrite)
12. `scripts/tools/zed.sh` (harden)

---

## Acceptance Test Checklist (Global)

After each tool/script implementation:

- [ ] Tool resolves from expected tier/path (`command -v`)
- [ ] Version command succeeds (`--version`/equivalent)
- [ ] Re-running installer is idempotent
- [ ] Linux and macOS behavior is documented
- [ ] Any required auth flow is documented and tested
- [ ] Changes reflected in docs when policy changed

---

## Notes

- Meta scripts (`scripts/meta/*`) remain deferred by plan.
- `dotfiles shell` is now the canonical shell bootstrap primitive.
- `toolbox-init` should continue to call `dotfiles shell` and `dotfiles sync` only (no host provisioning).
- If a tool shifts tier, update both this file and `AGENTS.md`.