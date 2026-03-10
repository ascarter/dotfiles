# Development Environment Implementation Guide

Read `AGENTS.md` first. This document is supporting detail and should remain aligned with it.

This document defines the detailed implementation model: tier philosophy, install patterns,
script taxonomy, and a rebuild checklist.

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
2. Bootstrap dotfiles: `install.sh` (or manual clone + `./install.sh`)
3. Run `dotfiles init` (XDG dirs, shell wiring, sync)
4. Run `dotfiles host init` (OS baseline provisioning — reboots may be required on Fedora Atomic)
5. Run `dotfiles gitconfig` (machine-specific git identity and credentials)
6. Install tools: `dotfiles tool install` (requires `gh`)
7. Run convenience scripts as needed (e.g. `dotfiles script developer`)
8. Authenticate credentials and verify environment

This lifecycle applies across Linux and macOS, with platform-specific details handled inside
`host/<platform>.sh`.

---

## Tier Model

### Tier 1: Host (OS-level)

Use host installs for tools that require OS integration, credential stores,
shell/session fundamentals, and container runtime support.

Typical host responsibilities:
- `git` (bootstrap prerequisite)
- shell/runtime basics (`zsh`, core utilities)
- container/toolbox runtime
- credential/keychain integration

Credential strategy:
- `gh` is required for GitHub authentication flows
- `git-credential-manager` is conditional and only required for non-GitHub hosts
  (currently Azure DevOps on macOS work environments)

### Tier 2: Layered Base (toolbox/container image)

Use for stable, universal command-line tools needed in every container:
- `ripgrep`, `jq`, `yq`, `just`, `git` (and optional `gh`)

### Tier 3: User-local (`XDG_OPT_HOME` + `XDG_BIN_HOME`)

Use for version managers and frequently updated developer tools:

- **`XDG_OPT_HOME` (opt-managed)**: GitHub release tools installed by `dotfiles tool install`
  (`ripgrep`, `jq`, `yq`, `just`, `fzf`, `serie`, `tree-sitter`, etc.)
- **`XDG_BIN_HOME`**: tools with their own installers
  (`fnm`, `rustup`, `uv`, `rv`, `go`, `claude`, `zed`, `codex`)

### Tier 4: Per-toolbox / Per-project

Use for isolated project dependencies and heavyweight/specialized system packages.

---

## Tool Placement Matrix

| Tool | Host | Layered | Opt-managed | XDG_BIN_HOME | Project |
|---|:---:|:---:|:---:|:---:|:---:|
| `gh` | optional | optional | — | optional | optional |
| `git-credential-manager` | yes | no | — | no | no |
| `ripgrep` | optional | yes | yes | — | optional |
| `jq` | optional | yes | yes | — | optional |
| `yq` | optional | yes | yes | — | optional |
| `just` | optional | yes | yes | — | optional |
| `fzf` | optional | — | yes | — | optional |
| `serie` | optional | — | yes | — | optional |
| `tree-sitter` | optional | — | yes | — | optional |
| `fnm` | no | no | — | yes | optional |
| `rustup` | no | no | — | yes | optional |
| `uv` | no | no | — | yes | optional |
| `rv` | no | no | — | yes | optional |
| `go` | optional | no | — | yes | optional |
| `claude` | no | no | — | yes | optional |
| `zed` | no | no | — | yes | optional |
| `codex` | no | no | — | yes | optional |

---

## Standard XDG Layout

Expected defaults (if not overridden):

- `XDG_BIN_HOME="$HOME/.local/bin"`
- `XDG_CONFIG_HOME="$HOME/.config"`
- `XDG_DATA_HOME="$HOME/.local/share"`
- `XDG_STATE_HOME="$HOME/.local/state"`
- `XDG_CACHE_HOME="$HOME/.cache"`
- `XDG_OPT_HOME="$HOME/.local/opt"`

---

## Linux Implementation (Fedora + Toolbox)

### 1) Bootstrap

```sh
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dotfiles/main/install.sh)"
dotfiles init
dotfiles host init        # rpm-ostree on Atomic variants; reboot required before next step
dotfiles gitconfig
```

### 2) Host-native install targets

Install/ensure on host:
- `git`, `zsh`, toolbox/container runtime
- `gh` (required baseline credential helper for GitHub)
- `git-credential-manager` (conditional; only where non-GitHub hosts are required)

For Fedora Atomic/Workstation, keep host package overlays minimal and focused on
OS integration and runtime.

### 3) Layered toolbox baseline

Create/maintain a base image with: `ripgrep`, `jq`, `yq`, `just`, `git` (and optional `gh`).

### 4) Toolbox initialization

Inside a toolbox container, run the same dotfiles bootstrap:

```sh
dotfiles init
dotfiles host init        # auto-detected as toolbox via /run/.toolboxenv
```

### 5) User-local toolchain

Use XDG-managed directories for language version managers:
- `RUSTUP_HOME="$XDG_DATA_HOME/rustup"`, `CARGO_HOME="$XDG_DATA_HOME/cargo"`
- `GOPATH="$XDG_DATA_HOME/go"`, `GOBIN="$XDG_BIN_HOME"`, `GOCACHE="$XDG_CACHE_HOME/go-build"`
- `FNM_DIR="$XDG_DATA_HOME/fnm"`

---

## macOS Implementation

### 1) Bootstrap

```sh
sh -c "$(curl -sSL https://raw.githubusercontent.com/ascarter/dotfiles/main/install.sh)"
dotfiles init
dotfiles host init        # installs Xcode CLT, Homebrew, runs brew bundle --global
dotfiles gitconfig
```

### 2) Package manager baseline

`dotfiles host init` runs `brew bundle --global` which covers:
- universal CLI baseline
- platform apps/casks
- optional host-level convenience tools

### 3) User-local parity with Linux

Use the same XDG local patterns for `fnm`, `rustup`, `uv`, `rv`, `go`, and developer CLIs.

---

## PATH and Shell Conventions

Recommended PATH order:
1. `$XDG_OPT_BIN` — opt-managed symlinks
2. `$XDG_BIN_HOME` — self-installed tools
3. `$DOTFILES_HOME/bin` — dotfiles CLI
4. manager-managed bin dirs (if not already linked)
5. system paths

Shell initialization for version managers lives in `config/zsh/interactive.d/`.

---

## Rebuild Checklist (From Zero)

### Pre-flight
- [ ] Backup SSH keys, GPG/Yubi configuration, and tokens
- [ ] Confirm network access and required org auth
- [ ] Confirm `git` available

### Bootstrap
- [ ] Clone/install dotfiles (`install.sh`)
- [ ] `dotfiles init`
- [ ] Re-open shell/session

### Host setup
- [ ] `dotfiles host init`
- [ ] Reboot if on Fedora Atomic (rpm-ostree changes require restart)
- [ ] Verify `gh` available; `dotfiles gitconfig`
- [ ] Verify shell default and XDG env exports

### Tools
- [ ] `dotfiles tool install`
- [ ] Run convenience scripts from `scripts/` as needed

### Toolbox bootstrap (per new container)
- [ ] Inside the container: `dotfiles init && dotfiles host init`
- [ ] Confirm toolbox env detected (`dotfiles host status`)

### Validation
- [ ] `dotfiles status` shows expected linked config
- [ ] `dotfiles host status` shows correct environment
- [ ] `command -v` resolves tools to intended tier
- [ ] IDEs detect toolchains and LSPs
- [ ] Authenticated workflows succeed (`gh`, git credentials, AI CLIs)

### Post-check
- [ ] Commit platform-specific adjustments back to dotfiles
- [ ] Update `AGENTS.md` if tier decisions changed

---

## Validation Commands

```sh
dotfiles status
dotfiles host status
command -v git gh jq yq rg just fnm rustup uv
echo "$XDG_BIN_HOME $XDG_OPT_BIN"
```

```sh
fnm --version && node --version
rustup show && cargo --version
go version
uv --version
```

---

## Git Credential Routing Policy

- GitHub remotes: `gh` credential integration (`gh auth setup-git`)
- Non-GitHub hosts (Azure DevOps): `git-credential-manager` — configured only when present
  and needed; currently required on macOS work setups

This allows personal Linux environments to remain simpler while supporting work
credential flows on macOS.

---

## Exception Policy

If a tool must be installed in a non-default tier:
- record reason (security/vendor/performance/compatibility)
- record affected platforms
- record rollback path
- update `AGENTS.md` placement notes
