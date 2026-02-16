# Development Environment Implementation Guide

This document defines the practical implementation of the tiered environment policy from `AGENTS.md`, including concrete install patterns, script taxonomy, command examples, and a rebuild checklist.

---

## Goals

- Keep host setup minimal and stable
- Use a layered baseline for container/toolbox environments
- Keep fast-moving developer tooling in user-local XDG paths
- Make Linux and macOS workflows as consistent as possible
- Support reproducible machine rebuilds
- Separate **OS baseline provisioning** from **tool/app provisioning**

---

## Canonical Lifecycle

Use this sequence as the default rebuild flow:

1. Install OS from scratch
2. Bootstrap dotfiles with `install.sh` (curl + execute)
3. Run host OS provisioning (baseline OS state)
4. Run package-manager baseline provisioning (where applicable)
5. Run shell bootstrap with `dotfiles shell`
6. Run meta scripts (or individual scripts) for tools/apps
7. Authenticate credentials and verify environment

This lifecycle should be mirrored across Linux and macOS, even if implementation details differ.

---

## Tier Model (Implementation)

## Tier 1: Host (OS-level)

Use host installs for tools that require OS integration, credential stores, shell/session fundamentals, and container runtime support.

Typical host responsibilities:

- `git` (bootstrap prerequisite)
- shell/runtime basics (`zsh`, core utilities)
- container/toolbox runtime
- credential/keychain integration
- `git-credential-manager` (preferred host-native integration)

## Tier 2: Layered Base (toolbox/container image)

Use for stable, universal command-line tools needed in every container:

- `ripgrep`
- `jq`
- `yq`
- `just`
- `git` (if base image doesn’t already include it)
- optional `gh`

## Tier 3: User-local (`XDG_DATA_HOME` + `XDG_BIN_HOME`)

Use for version managers and frequently updated developer tools shared across host and toolbox:

- `fnm`
- `rustup`
- `uv`
- `rv`
- user-managed `go`
- `helix`
- `serie`
- `codex`
- `copilot-cli`
- `claude code`
- `open code`
- optional `gh`

## Tier 4: Per-toolbox / Per-project

Use for isolated project dependencies and heavyweight/specialized system packages.

---

## Current Script Tree Analysis (`scripts/host`)

The current `scripts/host` directory mixes multiple concerns:

- **OS bootstrap**: `fedora.sh`, `macos.sh`
- **package manager bootstrap**: `homebrew.sh`
- **tool/app installers**: `ghostty.sh`, `tailscale.sh`, `proton.sh`, `speedtest.sh`, `vscode.sh`, `zed.sh`
- **host configuration generator**: `gitconfig.sh`

### What works well

- There is already platform branching for Linux/macOS
- Several scripts aim for idempotent behavior
- Some tools are already installed in user-local/XDG locations (good portability trend)

### What needs improvement

- Flat structure obscures lifecycle intent
- `dotfiles init` currently executes only a subset of scripts
- Script style is inconsistent (`sh` vs `bash`, non-portable conditionals in some files)
- Some scripts should be grouped by phase and capability, not by historical placement
- No formal meta script orchestration for “baseline” vs “devtools” vs “apps”

---

## Recommended Script Tree Organization

Refactor to a phase-oriented structure:

- `scripts/host/os/`
  - `fedora.sh`
  - `macos.sh`
- `scripts/host/pkg/`
  - `homebrew.sh`
  - future host package-layer scripts (`rpm-ostree-baseline.sh`, etc.)
- `scripts/host/config/`
  - `gitconfig.sh`
  - future machine-local configuration generators
- `scripts/tools/`
  - `ghostty.sh`, `tailscale.sh`, `proton.sh`, `speedtest.sh`, `vscode.sh`, `zed.sh`
  - future developer CLI installers
- `scripts/meta/`
  - `baseline.sh`
  - `devtools.sh`
  - `apps.sh`
  - `all.sh`

This gives both granular and bundled execution modes.

---

## Script Orchestration Pattern

## Baseline meta script

`baseline.sh` should orchestrate:

1. Host OS baseline (`scripts/host/os/<platform>.sh`)
2. Host package manager/bootstrap (`scripts/host/pkg/*`)
3. Baseline host requirements by capability:
   - terminal (`ghostty`) on Linux baseline hosts
   - secure network (`tailscale`) on Linux baseline hosts
4. Host configuration (`scripts/host/config/gitconfig.sh`)

## Devtools meta script

`devtools.sh` should install/update development tools (CLI + language managers), favoring user-local/XDG placement.

## Apps meta script

`apps.sh` should install optional GUI/workflow applications.

## All meta script

`all.sh` can run: `baseline -> devtools -> apps`, with flags to skip phases.

---

## Baseline Capability Policy (Linux vs macOS)

Treat capabilities as baseline requirements, not installer-specific requirements.

### Example: `ghostty`

- Linux: baseline requirement can be fulfilled by local AppImage install or host package
- macOS: fulfilled via Homebrew cask (`ghostty`)

### Example: `tailscale`

- Linux: baseline requirement via host package/layer and service enablement
- macOS: fulfilled via Homebrew cask (`tailscale-app`)

This keeps the policy consistent while allowing platform-specific implementation backends.

---

## Standard XDG Layout

Expected defaults (if not overridden):

- `XDG_BIN_HOME="$HOME/.local/bin"`
- `XDG_CONFIG_HOME="$HOME/.config"`
- `XDG_DATA_HOME="$HOME/.local/share"`
- `XDG_STATE_HOME="$HOME/.local/state"`
- `XDG_CACHE_HOME="$HOME/.cache"`

Recommended local tools layout:

- `$XDG_DATA_HOME/dev-tools/` (optional umbrella directory)
- `$XDG_DATA_HOME/fnm/`
- `$XDG_DATA_HOME/rustup/`
- `$XDG_DATA_HOME/cargo/`
- `$XDG_DATA_HOME/go/` (if managing Go in user space)
- `$XDG_BIN_HOME/` for shims/symlinks/binaries on PATH

---

## Linux Implementation (Fedora + Toolbox Style)

## 1) Host bootstrap

```/dev/null/shell.sh#L1-1
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dotfiles/main/install.sh)"
```

Then:

```/dev/null/shell.sh#L1-2
dotfiles init
dotfiles sync
```

## 2) Host-native install targets

Install/ensure on host:

- `git`
- `zsh`
- toolbox/container runtime
- `git-credential-manager` (native package/source recommended)

For Fedora Atomic/Workstation, keep host package overlays small and focused on integration/runtime.

## 3) Layered toolbox baseline

Create/maintain a base image that includes:

- `ripgrep`, `jq`, `yq`, `just`, `git` (and optional `gh`)

Example intent:

```/dev/null/shell.sh#L1-2
# inside image build context
dnf install -y ripgrep jq yq just git
```

Keep language version managers out of this layer by default.

## 4) User-local toolchain

Install local tools into XDG-managed directories where possible.

### fnm

- Install fnm binary in a user-local location
- Keep `FNM_DIR="$XDG_DATA_HOME/fnm"`
- Use shell integration from zsh config

### Rust

- Keep:
  - `RUSTUP_HOME="$XDG_DATA_HOME/rustup"`
  - `CARGO_HOME="$XDG_DATA_HOME/cargo"`
- Install via rustup and use cargo binaries from `$CARGO_HOME/bin`

### Go

- Keep:
  - `GOPATH="$XDG_DATA_HOME/go"`
  - `GOBIN="$XDG_BIN_HOME"`
  - `GOCACHE="$XDG_CACHE_HOME/go-build"`
- Use user-managed Go install and ensure PATH precedence

### Python tooling

- Keep `uv` and related Python CLIs user-local
- Prefer project virtual environments for dependencies

### Additional CLIs

Install these user-local and expose via `$XDG_BIN_HOME`:

- `codex`
- `copilot-cli`
- `claude code`
- `open code`
- `serie`
- optional `gh`

## 5) Toolbox path sharing

Ensure toolbox sessions can access:

- `$XDG_DATA_HOME`
- `$XDG_BIN_HOME`
- `$XDG_DATA_HOME/dotfiles`

Ensure PATH order prefers user-local shims/binaries before system fallbacks.

---

## macOS Implementation

Because there is no direct toolbox equivalent by default, split responsibilities between host-native and user-local.

## 1) Host-native essentials

Install (host-level):

- `git`
- `git-credential-manager`
- shell/runtime essentials
- keychain-integrated dependencies

## 2) Package manager baseline

Use Brewfile for broad baseline provisioning where appropriate:

- universal CLI baseline
- platform apps/casks
- optional host-level convenience tools

## 3) User-local parity with Linux

Use same XDG local patterns for:

- `fnm`
- `rustup`
- `uv`
- `rv`
- user-managed `go`
- `helix`
- `codex`
- `copilot-cli`
- `claude code`
- `open code`
- `serie`

Keep shell init semantics aligned with Linux so behavior is predictable.

---

## Tool Placement Matrix (Operational)

| Tool | Host | Layered | Local XDG | Project/Toolbox |
|---|---:|---:|---:|---:|
| `gh` | optional | optional | recommended | optional |
| `git-credential-manager` | yes | no | no | no |
| `helix` | optional | optional | yes | no |
| `ripgrep` | optional | yes | optional | optional |
| `serie` | optional | optional | yes | optional |
| `jq` | optional | yes | optional | optional |
| `yq` | optional | yes | optional | optional |
| `fnm` | no | no | yes | optional |
| `go` | optional | no | yes | optional |
| `just` | optional | yes | optional | optional |
| `rustup` | no | no | yes | optional |
| `rv` | no | no | yes | optional |
| `uv` | no | no | yes | optional |
| `copilot-cli` | no | no | yes | optional |
| `codex` | no | no | yes | optional |
| `claude code` | no | no | yes | optional |
| `open code` | no | no | yes | optional |

---

## PATH and Shell Conventions

- Keep `XDG_BIN_HOME` early in PATH
- Keep dotfiles `bin` in PATH
- Initialize version managers from `config/zsh/interactive.d/`
- Avoid hardcoded non-XDG paths unless forced by platform constraints

Recommended PATH intent:

1. `$XDG_BIN_HOME`
2. `$DOTFILES_HOME/bin`
3. manager-managed bin dirs (if not already linked into `XDG_BIN_HOME`)
4. system paths

---

## Practical Install Order (Fresh Machine)

1. Ensure `git` exists
2. Bootstrap dotfiles
3. Run `dotfiles init`
4. Run `dotfiles shell` (safe re-run; canonical shell bootstrap)
5. Run host provisioning scripts (platform-specific)
6. Install/verify host-native integration tools (`git-credential-manager`, etc.)
7. Run meta scripts (`baseline`, then `devtools`, then `apps` as needed)
8. Restart shell and validate PATH + binary resolution
9. Authenticate tools (`gh`, copilot/codex/claude, etc.)
10. Validate IDE/LSP behavior on representative projects

---

## Rebuild Checklist (From Zero)

Use this checklist for Linux/macOS rebuilds.

## Pre-flight

- [ ] Backup SSH keys, GPG/Yubi configuration, and tokens
- [ ] Confirm network access and required org auth
- [ ] Confirm `git` available

## Bootstrap

- [ ] Clone/install dotfiles
- [ ] Run `dotfiles init`
- [ ] Run `dotfiles shell`
- [ ] Run `dotfiles sync` (optional explicit verification run)
- [ ] Re-open shell/session

## Host setup

- [ ] Run host OS provisioning script for platform
- [ ] Run package manager baseline script(s)
- [ ] Install/verify `git-credential-manager`
- [ ] Verify shell default and XDG env exports

## Baseline/devtools/apps

- [ ] Run `baseline` meta script
- [ ] Run `devtools` meta script
- [ ] Run `apps` meta script (optional)

## Toolbox bootstrap (per new toolbox)

- [ ] Run `dotfiles script host/config/toolbox-init <container-name>`
- [ ] Use `--no-packages` if container-local package baseline should be skipped
- [ ] Confirm toolbox bootstrap runs only `dotfiles shell` + `dotfiles sync` (no host provisioning)

## Layered/container setup (if used)

- [ ] Build/update toolbox base image
- [ ] Ensure baseline tools available (`rg`, `jq`, `yq`, `just`, `git`)
- [ ] Verify user-local dirs are visible in toolbox sessions

## Validation

- [ ] `dotfiles status` shows expected linked config
- [ ] `which`/`command -v` resolves to intended tier
- [ ] IDEs (Zed/VS Code/Helix) detect toolchains and LSPs
- [ ] Authenticated workflows succeed (`gh`, git credentials, AI CLIs)

## Post-check

- [ ] Commit platform-specific adjustments back to dotfiles
- [ ] Update `AGENTS.md` if tier decisions changed
- [ ] Record exceptions and rationale

---

## Validation Commands (Suggested)

```/dev/null/shell.sh#L1-4
dotfiles status
command -v git gh jq yq rg just fnm go rustup uv rv hx
echo "$XDG_BIN_HOME"
echo "$XDG_DATA_HOME"
```

```/dev/null/shell.sh#L1-6
fnm --version
node --version
rustup show
cargo --version
go version
uv --version
```

---

## Migration Plan for Script Refactor (No-Break Approach)

1. Create new directories (`scripts/host/os`, `scripts/host/pkg`, `scripts/host/config`, `scripts/tools`, `scripts/meta`)
2. Move existing scripts to new homes
3. (Completed) Remove compatibility wrappers after command-path migration
4. Introduce meta scripts (`baseline`, `devtools`, `apps`, `all`)
5. Keep `dotfiles shell` as the canonical shell bootstrap path
6. Use toolbox bootstrap script (`host/config/toolbox-init`) instead of host provisioning in containers
7. Document each script’s tier and phase ownership

---

## Next Recommended Enhancements

1. Add `dotfiles doctor` for binary/path/tier validation
2. Normalize scripts to one shell style (`sh`-portable by default, `bash` only when required)
3. Enforce idempotence and clear non-interactive behavior
4. Document and test `dotfiles shell` behavior on host + toolbox
5. Split Brewfile sections into:
   - host integration
   - universal CLI baseline
   - apps/casks
6. Add toolbox base image definition in-repo for reproducibility
7. Add CI checks for script linting and policy drift

---

## Exception Policy

If a tool must be installed in a non-default tier:

- record reason (security/vendor/performance/compatibility)
- record affected platforms
- record rollback path
- update `AGENTS.md` placement notes