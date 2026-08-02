# dotfiles

Portable, XDG-based development configuration managed by
[mise](https://mise.jdx.dev/). Tested on macOS and Fedora Atomic Linux.

## Bootstrap

The host must provide `curl`, `git`, and `/bin/zsh`.

```sh
curl -fsSL https://raw.githubusercontent.com/ascarter/dotfiles/main/bootstrap.sh | sh
```

From an existing checkout, run:

```sh
./bootstrap.sh
```

The script installs mise at `~/.local/bin/mise`, clones this repository into
`~/Developer/dotfiles` when necessary, trusts its configuration, previews the
complete plan, and asks before applying it. Preview without applying the mise
bootstrap plan:

```sh
./bootstrap.sh --dry-run
```

Bootstrap does not install host packages or desktop applications. Homebrew,
RPM overlays, Flatpaks, fonts, and system services remain separate concerns.

## Update an existing system

Make a dotfiles change on one system, validate it, and commit and push it to
`main`. On every other bootstrapped system, propagate that change with:

```sh
dotfiles-update
```

The alias invokes the project-local task as
`mise -C "$DOTFILES_HOME" run update`, so it remains available from any
directory without adding a global mise task. The task refuses to run unless
the checkout is clean, on `main`, and has an upstream branch. It performs a
fast-forward-only pull, runs the normal bootstrap preview and confirmation,
and reports any remaining managed-state differences. It never stashes,
resets, merges, or resolves local work.

A pull may update the contents of existing linked files immediately, while
bootstrap creates new links, applies managed edits, installs newly declared
global tools, and runs setup tasks. To pull committed sources but only preview
the environment reconciliation, run:

```sh
dotfiles-update -- --dry-run
```

## What mise manages

- Files under `src/config/` are linked individually into `~/.config`, allowing
  application-owned and local files to coexist.
- A managed block in the otherwise local `~/.zshenv` establishes XDG paths and
  `ZDOTDIR`.
- `/bin/zsh` is selected as the login shell.
- The global mise configuration installs `gh`, Git LFS, and `usage`.
- Zsh loads generated completions for mise and usage; the usage CLI also
  enables argument completion for mise tasks that declare usage specs.
- The `dotfiles-update` shell alias invokes the project-local `update` task to
  propagate committed changes from any directory.
- The `bootstrap-git` task authenticates GitHub when needed and reconciles the
  locally owned `~/.gitconfig` with identity, HTTPS credential helpers, Git
  LFS, optional Azure DevOps GCM support, and the host diff/merge tool.

Language runtimes, language managers, formatters, language servers, debuggers,
and build tools belong to each project and its idiomatic files or `mise.toml`.

## Daily workflow

Check the managed state:

```sh
mise bootstrap status --missing
mise ls --current
```

Files already managed with `symlink-each` are live links. Edit their source in
this repository and verify the change normally:

```sh
$EDITOR src/config/ghostty/config
git diff --check
```

To add a new dotfile, create it beneath `src/config/` at its intended XDG path,
then preview and apply the new link:

```sh
mise bootstrap dotfiles apply --dry-run
mise bootstrap dotfiles apply --yes
mise bootstrap dotfiles status --missing
```

Add a global tool only when it is required outside project environments:

```sh
mise use -g jq
mise which jq
git diff -- src/config/mise/config.toml
```

`mise use -g` installs the tool, selects it globally, and writes
`~/.config/mise/config.toml`. That file is a managed link to
`src/config/mise/config.toml`, so the declaration becomes a reviewable
repository change.

Reconcile the complete workstation configuration at any time with:

```sh
./bootstrap.sh
```

The bootstrap is idempotent. It updates only the Git settings it owns and
preserves unrelated private or work settings in `~/.gitconfig`.

## Uninstall

Preview and then remove the mise-managed configuration:

```sh
./uninstall.sh --dry-run
./uninstall.sh
```

Uninstall removes the configured links, managed `.zshenv` block, mise tools,
and mise data. It preserves this checkout, GitHub authentication data, local
Git configuration, and the current login-shell selection.

## Layout

```text
.
├── .mise/
│   ├── config.toml
│   └── tasks/
├── AGENTS.md
├── bootstrap.sh
├── uninstall.sh
└── src/
    └── config/
```
