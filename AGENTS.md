# Repository instructions

Read `README.md` before changing this repository.

## Architecture

- Mise is the control plane for applying dotfiles, selecting the login shell,
  installing the global CLI baseline, and running setup tasks.
- `.mise/config.toml` owns bootstrap orchestration and the managed
  `~/.zshenv` block.
- `bootstrap.sh` handles the initial mise installation and repository clone,
  then delegates to `mise bootstrap`.
- `uninstall.sh` delegates dotfile removal and mise cleanup to mise while
  preserving locally owned state.
- `src/config/` mirrors `$XDG_CONFIG_HOME` and is applied to `~/.config` with
  `symlink-each`. It must coexist with application-owned and local files.
- Root home files remain locally owned. Mise manages only its marker-delimited
  block inside `~/.zshenv`.
- `.mise/tasks/bootstrap-git` reconciles only its owned keys in the real,
  untracked `~/.gitconfig`. Unrelated private and work settings remain there.
- The global mise tool baseline is deliberately limited to `gh` and Git LFS.
  Language runtimes, language managers, language servers, formatters, linters,
  debuggers, and build tools belong to their projects.
- `src/config/homebrew/Brewfile` is invoked separately with Homebrew. Host
  packages and desktop applications are not installed by bootstrap.
- OpenSSH configuration and authentication state remain local and unmanaged.

## Working rules

- Edit managed files through their repository paths under `src/config/`.
- New files beneath `src/config/` are discovered by the existing
  `symlink-each` mapping; do not add per-application dotfile entries.
- Keep bootstrap and uninstall behavior idempotent and previewable.
- Keep shell entry points portable `/bin/sh` unless a concrete requirement
  needs another interpreter.
- Do not add host package or service mutations to the user bootstrap.
- Do not add a global development tool when a project can declare it.
- Add an approved global tool with `mise use -g TOOL`, then review the change
  written through the managed global-config link to
  `src/config/mise/config.toml`.

## Safety

- Never commit or print tokens, private keys, credentials, machine identity,
  shell history, or other private state.
- Do not overwrite locally owned files. Resolve dotfile conflicts explicitly.
- Do not install, remove, or modify host packages or services unless the user
  explicitly requests that work.
- Preserve unrelated worktree changes and stage only the intended paths.

## Validation

Before committing bootstrap or managed-configuration changes, run:

```sh
sh -n bootstrap.sh uninstall.sh .mise/tasks/bootstrap-git
mise fmt --check
git diff --check
mise bootstrap status --missing
./bootstrap.sh --dry-run
./uninstall.sh --dry-run
```

The bootstrap dry-run may install mise and clone the repository when they are
absent, but it must not apply the mise bootstrap plan. The uninstall dry-run
must never remove state.
