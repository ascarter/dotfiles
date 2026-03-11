# Refactor: Declarative tool driver

## Problem
Tool scripts are imperative — each reimplements the same boilerplate (source opt.sh,
tool_check, platform detection, tool_gh_install, tool_link, echo done). The standard
GitHub-release flow is duplicated across 7+ scripts. Custom installers (curl, package
manager, AppImage) are mixed in with the same structure but entirely different logic.

## Design

### Core idea
Invert control. Tool scripts become **declarative config files** that set variables
and optionally define hook functions. A **driver** in `lib/opt.sh` (or a new
`lib/tool-driver.sh`) reads the config and executes the standard flow, calling hooks
at extension points.

### Tool script anatomy (new)

```bash
#!/usr/bin/env bash
# tools/fzf.sh — pure config, no logic needed
TOOL_CMD=fzf
TOOL_REPO=junegunn/fzf
TOOL_ASSET_aarch64_darwin="fzf-*-darwin_arm64.tar.gz"
TOOL_ASSET_x86_64_darwin="fzf-*-darwin_amd64.tar.gz"
TOOL_ASSET_aarch64_linux="fzf-*-linux_arm64.tar.gz"
TOOL_ASSET_x86_64_linux="fzf-*-linux_amd64.tar.gz"
TOOL_LINKS=(bin/fzf)
```

### Config variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TOOL_CMD` | yes | Binary name for `command -v` check |
| `TOOL_REPO` | no | GitHub `owner/repo` (triggers gh-release flow) |
| `TOOL_ASSET_<platform>` | if TOOL_REPO | Asset glob per platform |
| `TOOL_LINKS` | no | Array of `<src>:<dst>` or just `<dst>` symlinks |
| `TOOL_MAN_PAGES` | no | Array of man page paths to link |
| `TOOL_COMPLETIONS` | no | Array of completion files to link |
| `TOOL_TYPE` | no | Override auto-detection: `gh`, `curl`, `pkg`, `custom` |

### Hook functions (optional overrides)

| Hook | Default behavior | When to override |
|------|-----------------|------------------|
| `tool_download` | `tool_gh_install` using TOOL_REPO + asset | go.sh (go.dev API), curl installers |
| `tool_post_install` | Create symlinks from TOOL_LINKS | ghostty (desktop integration), ripgrep (find binary in subdir) |
| `tool_platform_check` | Allow all | gh.sh (macOS → "use brew", Linux → pkg manager) |

### Driver flow

```
1. Source the tool script (sets vars, defines hooks)
2. tool_check $TOOL_CMD               — skip if installed (unless upgrade)
3. tool_platform_check                 — bail with guidance if unsupported
4. tool_download                       — default: tool_gh_install
5. tool_post_install                   — default: create TOOL_LINKS symlinks
6. Log completion
```

### Tool categories mapped to new model

**Pure config (gh-release, no hooks needed):**
- fzf, serie, just (simple binary + optional man/completions)

**Config + post_install hook (gh-release, custom linking):**
- ripgrep (binary in subdirectory, man pages, completions)
- jq, yq (plain binary asset → rename)
- tree-sitter (.gz binary → rename)

**Custom download hook:**
- go.sh (go.dev API, checksum, cellar with current symlink)
- rustup, uv, rv, claude, fnm (curl | sh installers)
- zed (curl installer)

**Platform-specific dispatch (platform_check hook):**
- gh.sh (macOS → "use brew", Linux/Fedora → dnf)
- ghostty.sh (macOS → "use brew", Linux → AppImage + desktop)
- vscode.sh (macOS → "use brew", Linux → tarball + desktop)

## Workplan

- [x] Design and implement the driver function in lib/opt.sh
- [x] Convert one simple gh-release tool (fzf) as proof of concept
- [ ] Convert remaining simple gh-release tools (serie, just)
- [ ] Convert gh-release tools with custom linking (ripgrep, jq, yq, tree-sitter)
- [ ] Convert curl-installer tools (rustup, uv, rv, claude, fnm, zed)
- [ ] Convert platform-dispatch tools (gh, ghostty, vscode)
- [ ] Convert custom-download tool (go)
- [ ] Verify `dotfiles tool install/upgrade/list/status` all work
- [x] Update AGENTS.md tool script documentation

## Resolved questions
- Driver lives in `lib/opt.sh` (no separate file).
- `TOOL_LINKS` uses `src:dst` syntax; bare `name` is shorthand for `name:bin/name`.
- Asset vars use readable platform names: `TOOL_ASSET_MACOS_ARM64`, `TOOL_ASSET_LINUX_AMD64`, etc.
- Recipes are non-executable config files sourced by the driver (not scripts that call the driver).
- Recipe detection: no shebang = recipe; shebang = legacy script.
- Curl installers: keep as full hook functions (each has unique logic).

## Migration strategy
- Convert one tool at a time, test after each
- Old imperative style continues to work alongside new declarative style
- Driver detects whether a script has a shebang (legacy) or not (recipe)
- No flag day — gradual migration
