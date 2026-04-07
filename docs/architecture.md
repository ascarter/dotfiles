# Architecture

This repository makes a machine become your workstation. It owns the bridge
between a bare OS install and a productive development environment — and
deliberately stops there.

## Layer Model

The development environment is built in five layers. This repo owns layers 1–3;
layers 4–5 are mentioned only to draw the boundary.

| Layer | Responsibility | Owned by this repo | Examples |
|-------|---------------|:------------------:|----------|
| 1. Host OS baseline | OS packages, desktop apps, system config | ✓ | brew, rpm-ostree, dnf |
| 2. Workstation CLI tools | Cross-platform portable binaries | ✓ | aqua (fzf, ripgrep, jq, delta, …) |
| 3. Language version managers | Runtime toolchains | ✓ | rustup, uv, fnm |
| 4. Project-local environments | Per-repo deps and config | ✗ | Cargo.toml, pyproject.toml, package.json |
| 5. Agent behavior | AI assistant configuration | ✗ | .github/copilot-instructions.md |

### Layer 1 — Host OS baseline

Platform-native package managers install OS-integrated software: shells,
credential helpers, desktop apps, hardware drivers. Each platform has its own
bootstrap script and package manifest.

- **macOS** — Homebrew (`Brewfile`)
- **Fedora Atomic** — rpm-ostree (`overlay-packages.txt`)
- **Toolbox** — dnf (`dnf-packages.txt`)

### Layer 2 — Workstation CLI tools

[aqua](https://aquaproj.github.io/) manages portable CLI binaries from GitHub
releases. Tools are declared in `config/aquaproj-aqua/` and organized into
import files (`core.yaml`, `editors.yaml`, `languages.yaml`, `agents.yaml`).

aqua is installed by the host layer (Homebrew on macOS, standalone installer on
Linux) and invoked during bootstrap with `aqua i -a`.

### Layer 3 — Language version managers

Language-specific version managers (rustup, uv, fnm) install themselves into
XDG-compliant paths and manage their own toolchains. This repo provides shell
configuration that integrates them into `PATH` but does not wrap or re-implement
their commands.

## Architectural Boundary

**This repo owns:**

- XDG directory structure and shell bootstrap (`dotfiles init`)
- Config files synced into `$XDG_CONFIG_HOME` (`dotfiles sync`)
- Host provisioning scripts (`dotfiles host init`)
- aqua tool declarations (`config/aquaproj-aqua/`)
- Machine-specific gitconfig generation (`dotfiles gitconfig`)
- Health checks (`dotfiles doctor`)

**This repo does not own:**

- Project-level dependency management
- Container image definitions
- CI/CD pipelines
- AI agent system prompts (beyond the repo's own `.github/copilot-instructions.md`)

## Command Philosophy

Use native tools directly. The `dotfiles` CLI wraps only workstation-specific
policy — bootstrapping, config sync, and health checks. It does not reimplement
or proxy commands that already have good interfaces.

```
# Yes — native tool, native interface
brew update && brew upgrade
aqua update
aqua i -a

# No — shadow CLI that mirrors upstream
dotfiles tool update    # removed
dotfiles tool install   # removed
```

### No shadow CLIs

If a command would just be a thin wrapper around `brew`, `aqua`, `rpm-ostree`,
or any other tool, don't build it. Users should learn and use the native tool's
interface. The `dotfiles` CLI exists for operations that are genuinely
workstation-specific:

- `dotfiles init` — sets up XDG dirs and shell bootstrap
- `dotfiles sync` — symlinks config into place
- `dotfiles host init` — runs the platform bootstrap sequence
- `dotfiles doctor` — checks that everything is wired correctly

## The Guiding Question

Before adding anything to this repo, ask:

> **Does this help make a machine become my workstation?**

If the answer is no — if it's project-specific, or duplicates an existing tool's
interface, or manages runtime dependencies — it belongs somewhere else.
