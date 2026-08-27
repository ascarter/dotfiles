# Repository instructions

Read `README.md` before changing this repository.

## Architecture

- Mise is the control plane for applying dotfiles, selecting the login shell,
  installing the global CLI baseline, applying platform settings and packages,
  and running setup tasks.
- `mise/config.toml` is both the repository bootstrap config and the source of
  the managed global mise config. It owns the shared workstation baseline,
  bootstrap orchestration, dotfile mappings, the managed `~/.zshenv` block,
  and personal Git tasks.
- `mise/config.macos.toml` and `mise/config.linux.toml` are automatically
  selected platform overlays. The Linux overlay owns the `rpm-ostree` plugin;
  the macOS overlay owns bootstrap-managed macOS defaults and hooks.
- `mise/conf.d/` divides aliases, tools, packages, and app tasks by concern.
  `mise/miserc.toml` enables automatic environments and environment-aware
  `conf.d` fragments. This repository has no workstation profile or managed
  `MISE_ENV` selection block.
- `bootstrap.sh` handles the initial mise installation and repository clone,
  trusts the checkout, then forwards arguments to `mise bootstrap`.
- `uninstall.sh` unapplies managed dotfiles and delegates mise removal to
  `mise implode`, preserving the checkout and nonempty local mise config.
- `config/` mirrors `$XDG_CONFIG_HOME` except for `mise/`, which is managed
  separately as `~/.config/mise`; both mappings use `symlink-each`. They must
  coexist with application-owned and local files; new children are picked up
  without adding individual mappings.
- Root home files remain locally owned. Mise manages its marker-delimited
  block in `~/.zshenv`. Managed Zsh files under `.config/zsh/` source local
  `~/.zprofile` and `~/.zshrc` extensions.
- `config/git/config` contains portable Git behavior. Bootstrap tasks under
  `mise/config.toml` configure GitHub authentication, local Git
  identity, Git LFS, and optionally Git Credential Manager in the real,
  untracked user state. Personal Git and GitHub setup runs only when its leaf
  tasks are invoked directly.
- The `dotfiles-update` alias pulls the configured checkout branch, then runs
  `mise bootstrap --update` from that checkout.
- The global tool baseline is declared in `mise/conf.d/tools.toml`.
  Project-specific runtimes, language servers, formatters, linters, debuggers,
  and build tools belong to their projects.
- `mise/conf.d/packages.macos.toml` owns the focused macOS GUI and App Store
  package set. `config/homebrew/Brewfile` is the broader host package manifest invoked
  separately with `brew bundle --global`.
- OpenSSH configuration and authentication state remain local and unmanaged.

## Working rules

- Edit ordinary managed files through their repository paths under `config/`;
  edit mise through `mise/`.
- New files beneath `config/` or `mise/` are discovered by the existing
  `symlink-each` mappings; do not add per-application dotfile entries.
- Keep bootstrap and uninstall behavior idempotent and previewable.
- Keep vendor-installer tasks minimal and invoke the official installer
  directly.
- Keep root shell entry points portable `/bin/sh`. Mise task scripts may use
  Bash when their task metadata or implementation requires it.
- Put shared behavior in `mise/config.toml`, platform settings in the matching
  `mise/config.<platform>.toml` overlay, and concern-specific configuration in
  `mise/conf.d/`. Do not introduce profile selection for ordinary platform
  differences.
- Keep platform defaults, hooks, and prerequisites narrowly scoped and
  previewable. Keep the focused macOS package set in its platform-specific
  fragment and put the broader manually applied macOS host inventory in the
  Brewfile.
- Do not add a global development tool when a project can declare it.
- Add an approved global tool with `mise use -g TOOL`, then review the change
  written through the managed global-config link to
  `mise/config.toml`.
- Keep Neovim's global configuration limited to editor behavior, plugins, and
  a small parser baseline. Language servers, formatters, linters, runtimes,
  and debug adapters must be supplied by projects.

## Safety

- Never commit or print tokens, private keys, credentials, machine identity,
  shell history, or other private state.
- Do not overwrite locally owned files. Resolve dotfile conflicts explicitly.
- Do not install, remove, or modify host packages or services unless the user
  explicitly requests that work.
- Do not run `bootstrap.sh`, `uninstall.sh`, or commands that apply, unapply,
  install, remove, prune, or implode managed state against the running system
  unless the user explicitly requests it. A dry-run flag does not waive this
  rule because wrapper scripts may perform other side effects first.
- Preserve unrelated worktree changes and stage only the intended paths.

## Validation

Use only validation that reads or formats files in the checkout by default:

```sh
sh -n bootstrap.sh uninstall.sh
mise fmt
mise fmt --check
mise tasks validate
git diff --check
```
