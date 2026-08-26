# Repository instructions

Read `README.md` before changing this repository.

## Architecture

- Mise is the control plane for applying dotfiles, selecting the login shell,
  installing the global CLI baseline, applying platform settings and packages,
  and running setup tasks.
- `.config/mise/config.toml` is both the repository bootstrap config and the
  source of the managed global mise config. It owns shared tools, aliases,
  bootstrap orchestration, the dotfile mapping, the managed `~/.zshenv`
  block, and the optional `bootstrap:workstation` task.
- `.config/mise/conf.d/` contains environment- and platform-specific
  fragments. `config.workstation.toml` owns the optional workstation profile,
  including the `rpm-ostree` plugin, login-shell selection, and its managed
  environment block. `packages.workstation.toml` owns workstation packages,
  Fedora repositories and RPM app setup, and workstation app installers.
- `.config/mise/miserc.toml` enables mise automatic environment detection so
  the repository config and applicable fragments load from this checkout. The
  workstation profile writes a managed `~/.miserc.toml` block that activates
  the `workstation` environment.
- `bootstrap.sh` handles the initial mise installation and repository clone,
  trusts the checkout, then forwards arguments to `mise bootstrap`.
- `uninstall.sh` unapplies managed dotfiles and delegates mise removal to
  `mise implode`, preserving the checkout and nonempty local mise config.
- `.config/` mirrors `$XDG_CONFIG_HOME` and is applied to `~/.config` with
  `symlink-each`. It must coexist with application-owned and local files; new
  children are picked up without adding individual mappings.
- Root home files remain locally owned. Mise manages its marker-delimited
  block in `~/.zshenv`. Managed Zsh files under `.config/zsh/` source local
  `~/.zprofile` and `~/.zshrc` extensions.
- `.config/git/config` contains portable Git behavior. Bootstrap tasks under
  `.config/mise/config.toml` configure GitHub authentication, local Git
  identity, Git LFS, and optionally Git Credential Manager in the real,
  untracked user state. Personal Git and GitHub setup runs only through the
  optional `bootstrap:workstation` task or when its leaf tasks are invoked
  directly.
- The `dotfiles-update` alias delegates directly to `mise bootstrap`; it does
  not pull or enforce a branch or worktree policy.
- The global tool baseline is declared in `.config/mise/config.toml`.
  Project-specific runtimes, language servers, formatters, linters, debuggers,
  and build tools belong to their projects.
- `.config/mise/config.macos.toml` owns bootstrap-managed macOS defaults,
  hooks, aliases, platform prerequisites, and the focused GUI and App Store
  package set.
  `.config/homebrew/Brewfile` is the broader host package manifest invoked
  separately with `brew bundle --global`.
- OpenSSH configuration and authentication state remain local and unmanaged.

## Working rules

- Edit ordinary managed files through their repository paths under
  `.config/`; edit mise through `.config/mise/`.
- New files beneath `.config/` are discovered by the existing
  `symlink-each` mapping; do not add per-application dotfile entries.
- Keep bootstrap and uninstall behavior idempotent and previewable.
- Keep vendor-installer tasks minimal and invoke the official installer
  directly.
- Keep root shell entry points portable `/bin/sh`. Mise task scripts may use
  Bash when their task metadata or implementation requires it.
- Put shared behavior in `config.toml`, macOS-specific behavior in the macOS
  fragment, and optional workstation setup in the workstation fragments and
  `bootstrap:workstation`.
- Keep platform defaults, hooks, and prerequisites narrowly scoped and
  previewable. Keep the focused macOS package set in its platform overlay and
  put the broader manually applied macOS host inventory in the Brewfile.
- Do not add a global development tool when a project can declare it.
- Add an approved global tool with `mise use -g TOOL`, then review the change
  written through the managed global-config link to
  `.config/mise/config.toml`.
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
