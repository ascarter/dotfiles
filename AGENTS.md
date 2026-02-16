# AGENTS.md

## Purpose

This document defines how agents (human or automated) should structure, provision, and maintain this dotfiles-managed development environment across Linux (host + toolbox-style containers) and macOS.

The goals are:

- Consistent developer experience across machines
- Clear boundaries between host, layered/container, and user-local installs
- Reproducible rebuilds with minimal drift
- XDG-first layout for portability and clean system state
- Predictable provisioning lifecycle and script organization

---

## Source of Truth

- Dotfiles repository root: `dotfiles/`
- Configuration files synced from: `dotfiles/config/` ➜ `${XDG_CONFIG_HOME}`
- Primary command entrypoint: `dotfiles/bin/dotfiles`
- Provisioning and install automation: `dotfiles/scripts/`
- Homebrew bundle: `dotfiles/config/homebrew/Brewfile`
- Implementation guide: `dotfiles/docs/dev-environment.md`

When in doubt, automate through this repository rather than manual one-off system edits.

---

## Environment Model

Use four installation tiers:

1. **Host (OS-level)**
2. **Layered base (container/toolbox image)**
3. **User-local (`XDG_DATA_HOME` + `XDG_BIN_HOME`)**
4. **Per-toolbox / per-project**

Decisions should optimize for:

- Cross-platform consistency
- Security and credentials integration
- Upgrade cadence
- Isolation needs
- Startup/runtime ergonomics

---

## Tool Placement Policy

### 1) Host (OS-level)

Install here when the tool needs deep OS integration, credential store access, or must exist before user environment bootstraps.

**Required host responsibilities**
- `git` availability (bootstrap prerequisite)
- Shell/runtime basics (`zsh`, core host tools)
- Container/toolbox runtime
- Credential/keychain integration layers

**Preferred host-native tools**
- `git-credential-manager` (OS keychain/credential store integration)

---

### 2) Layered Base (toolbox/container image)

Install stable, universal CLI utilities here when they should be present in every container without per-user bootstrapping.

**Recommended layered baseline**
- `ripgrep`
- `jq`
- `yq`
- `just`
- `git` (if base image does not already provide it)
- optionally `gh` for convenience

Keep layered images lean. Avoid frequent-churn language/version managers in this layer.

---

### 3) User-local (`XDG_DATA_HOME` + `XDG_BIN_HOME`)

Install fast-moving CLIs, version managers, and user-scoped toolchains here to share between host and toolbox/dev shells.

**Primary local candidates**
- `fnm`
- `rustup`
- `uv`
- `rv`
- `go` (user-managed toolchain)
- `helix`
- `codex`
- `copilot-cli`
- `claude code`
- `open code`
- `serie`
- optionally `gh` (if host integration is still satisfied)

This is the preferred tier for consistency across Linux and macOS user environments.

---

### 4) Per-toolbox / Per-project

Install here when dependencies are project-specific, heavy, or intentionally isolated.

Examples:
- Project-native build dependencies
- Specialized SDK/system libraries
- Team-specific pinned binaries not suitable globally

---

## Canonical Placement Matrix (Initial)

| Tool | Host | Layered Base | User-local | Per-toolbox |
|---|---:|---:|---:|---:|
| `gh` | optional | optional | recommended | optional |
| `git-credential-manager` | **yes** | no | no | no |
| `helix` | optional | optional | **yes** | no |
| `ripgrep` | optional | **yes** | optional | optional |
| `serie` | optional | optional | **yes** | optional |
| `jq` | optional | **yes** | optional | optional |
| `yq` | optional | **yes** | optional | optional |
| `fnm` | no | no | **yes** | optional |
| `go` | optional | no | **yes** | optional |
| `just` | optional | **yes** | optional | optional |
| `rustup` | no | no | **yes** | optional |
| `rv` | no | no | **yes** | optional |
| `uv` | no | no | **yes** | optional |
| `copilot-cli` | no | no | **yes** | optional |
| `codex` | no | no | **yes** | optional |
| `claude code` | no | no | **yes** | optional |
| `open code` | no | no | **yes** | optional |

Notes:
- “optional” means acceptable based on workflow preference.
- If duplicated across layers, ensure PATH precedence is intentional and documented.
- Capability requirements may be constant while install backend differs by platform (example: `tailscale`, `ghostty`).

---

## Provisioning Lifecycle (Canonical)

Provisioning should follow this lifecycle:

1. **Install OS from scratch**
2. **Run bootstrap** via `install.sh` (curl invocation) to place dotfiles in `${XDG_DATA_HOME}/dotfiles`
3. **Run host OS provisioning** script to baseline the machine
4. **Run capability scripts** either:
   - individually (granular installs), or
   - via meta scripts (`baseline`, `devtools`, `apps`, `all`)
5. **Validate environment** (`dotfiles status`, PATH resolution, auth, toolchain checks)

This flow is the baseline for Linux and macOS, with provider differences hidden behind script layers.

---

## Script Taxonomy Policy

The scripts tree must reflect **intent** and **lifecycle phase**. Avoid mixing OS bootstrap logic and user-app installers in one flat namespace.

### Required taxonomy

Organize scripts into phase/scope groups:

- `scripts/host/os/`
  - OS baseline provisioning only (e.g., Fedora/macOS host prep)
- `scripts/host/pkg/`
  - host package manager bootstrapping/config (e.g., Homebrew setup)
- `scripts/host/config/`
  - host configuration synthesis (e.g., `gitconfig` generation)
- `scripts/tools/`
  - individual tool/app installers (CLI/editor/network apps)
- `scripts/meta/`
  - orchestration scripts composing phases and profiles

### Script classes

1. **OS baseline scripts**
   - Platform bootstrap, runtime prerequisites, shell baseline
2. **Capability scripts**
   - Install one capability/tool at a time (`ghostty`, `tailscale`, `vscode`, etc.)
3. **Meta/profile scripts**
   - Install sets: `baseline`, `devtools`, `apps`, `all`

### Naming rules

- Names describe capability, not installer backend
- Platform differences handled inside script logic or delegated wrappers
- Avoid ambiguous names that combine unrelated concerns

---

## Host Scripts Review Summary (Current State)

Current `scripts/host/` includes mixed concerns:
- OS provisioning (`fedora`, `macos`)
- package manager bootstrap (`homebrew`)
- app/tool install/config scripts (`ghostty`, `tailscale`, `proton`, `vscode`, `zed`, `speedtest`, `gitconfig`)

### Risks from current structure

- Flat namespace hides lifecycle intent
- Harder to define reliable “run-all” flows
- Inconsistent idempotence/quality across scripts
- Mixed shell dialect (`sh` + `bash`) and style inconsistencies
- Platform-specific behavior is present but not consistently abstracted

### Refactor principle

Refactor structure first (taxonomy), then improve script internals while preserving behavior.

---

## Cross-Platform Capability Policy

Treat baseline requirements as **capabilities**, not package managers.

Examples:

- **Terminal capability (`ghostty`)**
  - Linux: local/appimage or host package path
  - macOS: Homebrew cask path
- **Secure network capability (`tailscale`)**
  - Linux: host package + service enablement
  - macOS: Homebrew cask/app path

The capability must be consistent, while provider can differ by platform.

---

## Meta Script Policy (Recommended Profiles)

Define and maintain meta scripts in `scripts/meta/`:

- `baseline`
  - host baseline + required baseline capabilities
- `devtools`
  - developer CLI/toolchain profile
- `apps`
  - editor/UI app profile
- `all`
  - full workstation profile (`baseline + devtools + apps`)

Meta scripts must be idempotent and safe to re-run.

---

## Script Quality Standards

All scripts must:

1. Be idempotent and re-runnable
2. Fail fast with clear errors
3. Avoid hidden side effects
4. Respect XDG paths for user-local installs
5. Avoid unnecessary privilege escalation
6. Gate platform-specific actions explicitly
7. Support non-interactive automation where reasonable
8. Use consistent shell style and quoting discipline

### Shell standard

- Default: POSIX `sh` unless Bash features are explicitly required
- If Bash is required, declare `#!/usr/bin/env bash` and keep usage intentional
- Do not use Bash-only syntax in `sh` scripts

---

## Refactor Policy and Migration Strategy

When refactoring scripts:

1. **Preserve behavior first**
2. **Move files into taxonomy directories**
3. **Provide compatibility wrappers/aliases** for old script names during transition
4. **Update meta scripts and documentation**
5. **Then improve internals** (idempotence, validation, logging)
6. **Remove deprecated wrappers** after a defined transition period

### Suggested mapping (conceptual)

- `fedora`, `macos` ➜ `host/os/`
- `homebrew` ➜ `host/pkg/`
- `gitconfig` ➜ `host/config/`
- `ghostty`, `tailscale`, `proton`, `speedtest`, `vscode`, `zed` ➜ `tools/`
- new orchestrators ➜ `meta/`

---

## Linux and macOS Strategy Notes

### Linux (host + toolbox)

1. Keep host minimal and stable
2. Use layered baseline image for universal CLI tools
3. Share user-local XDG tool dirs into toolbox sessions
4. Install fast-moving tools user-local via version managers and per-tool scripts

### macOS

1. Keep OS-integrated items host-native
2. Use Homebrew as platform package/install backend where appropriate
3. Keep user-local XDG parity for fast-moving tooling
4. Preserve the same lifecycle phases and profile script semantics

---

## PATH and Shell Rules

- `XDG_BIN_HOME` should be early in PATH
- Dotfiles-managed `bin` directory should also be in PATH
- Version manager init scripts should be loaded from shell modules under `config/zsh/interactive.d/`
- Do not hardcode non-XDG paths unless platform constraints require it

---

## Agent Operating Rules

When making changes in this repo:

1. **Prefer additive, reversible changes**
2. **Do not move tools between tiers without recording rationale** in this file
3. **Keep host scripts idempotent** and safe to re-run
4. **Avoid hidden side effects** (silent credential/config rewrites)
5. **Document new tool placement and script taxonomy impact**
6. **Align Linux + macOS behavior** whenever feasible
7. **Minimize privilege escalation**; use user-local installs by default
8. **Keep script taxonomy coherent** (no new flat-mix regressions)

---

## Change Management Checklist

Before merging provisioning/tooling changes, verify:

- [ ] Tool tier placement follows this policy
- [ ] XDG paths are respected
- [ ] Host scripts remain idempotent
- [ ] PATH precedence is intentional
- [ ] Linux and macOS behavior is documented
- [ ] Script fits taxonomy (`host/os`, `host/pkg`, `host/config`, `tools`, `meta`)
- [ ] Meta profile behavior is documented (if affected)
- [ ] Rebuild path from clean machine is still valid
- [ ] README/install flow remains accurate

---

## Decision Overrides

Exceptions are allowed when justified by:

- Security requirements
- Vendor installation constraints
- Performance constraints
- Team/project compatibility constraints

Any override must include:
- What changed
- Why it changed
- Which platforms are affected
- Rollback path

---

## Summary

Default approach:

- **Host:** only what needs OS integration
- **Layered:** stable universal CLI baseline
- **Local (XDG):** version managers + fast-moving developer tools
- **Per-toolbox/project:** isolated or heavy project-specific dependencies
- **Scripts:** organized by lifecycle and scope, with meta orchestration for repeatable profiles

This policy is the baseline for future environment automation in this repository.