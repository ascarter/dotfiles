# Repository instructions

Read `README.md` before changing this repository.

## Architecture

- Mise is the control plane for applying dotfiles, installing the global CLI
  baseline, applying platform settings and packages, and running setup tasks.
- The repository is the global mise configuration. `mise bootstrap --from-git`
  clones it directly into `$MISE_CONFIG_DIR`, normally `~/.config/mise`, where
  the checkout remains active for future mise invocations.
- Root `config.toml` owns the shared host baseline, bootstrap orchestration,
  dotfile mappings, managed `~/.zshenv` block, shell activation, login shell,
  and personal Git tasks.
- `config.macos.toml` is selected automatically on macOS and owns managed
  macOS defaults and hooks. `conf.d/packages.linux.toml` owns the Fedora Atomic
  package baseline and `rpm-ostree` plugin.
- `conf.d/` divides aliases, tools, packages, and app tasks by concern.
  `miserc.toml` enables automatic platform environments and environment-aware
  fragments. There are no explicit workstation, developer, or container
  profiles.
- `bootstrap.sh` installs or updates mise, exports early config-discovery
  settings, and forwards arguments to `mise bootstrap --from-git`. Mise owns
  clone validation, trust for the bootstrap invocation, and fast-forward
  updates.
- `uninstall.sh` unapplies managed dotfiles and delegates mise removal to
  `mise implode`, preserving the global configuration checkout.
- `src/config/` mirrors `$XDG_CONFIG_HOME` through `symlink-each`. It must
  coexist with the repository at `~/.config/mise` and with application-owned
  or local files; new children are picked up without individual mappings.
- Root home files remain locally owned. Mise manages marker-delimited blocks
  in `~/.zshenv`. Managed Zsh files under `src/config/zsh/` source local
  `~/.zprofile` and `~/.zshrc` extensions.
- `src/config/git/config` contains portable Git behavior. Bootstrap tasks in
  `config.toml` configure GitHub authentication, local Git identity, Git LFS,
  and optionally Git Credential Manager in real, untracked user state.
- The `dotfiles-update` alias delegates checkout refresh and reconciliation to
  `mise bootstrap --from-git ... --update`.
- The minimal global tool baseline is declared in `conf.d/tools.toml`.
  Project-specific runtimes, language servers, formatters, linters, debuggers,
  and build tools belong to their projects.
- `conf.d/packages.macos.toml` owns the focused macOS GUI and App Store package
  set.
- OpenSSH configuration and authentication state remain local and unmanaged.

## Working rules

- Edit ordinary managed files through `src/config/`; edit mise configuration
  through the root config files, `conf.d/`, and `tasks/`.
- New files beneath `src/config/` are discovered by the existing
  `symlink-each` mapping; do not add per-application dotfile entries.
- Keep bootstrap and uninstall behavior idempotent and previewable.
- Keep vendor-installer tasks minimal and invoke the official installer
  directly.
- Keep root shell entry points portable `/bin/sh`. Mise task scripts may use
  Bash when their task metadata or implementation requires it.
- Put shared behavior in `config.toml`, platform settings in the matching
  `config.<platform>.toml` overlay, and concern-specific configuration in
  `conf.d/`. Use automatic platform environments instead of explicit profiles.
- Keep the default bootstrap scoped to clean macOS and Fedora Atomic hosts.
  Add Fedora Workstation, development, or container behavior only in targeted
  follow-up work.
- Keep platform defaults, hooks, and prerequisites narrowly scoped and
  previewable. Keep platform-only plugins, hooks, packages, and aliases in
  environment-suffixed fragments so they do not load on other platforms.
- Do not add a global development tool when a project can declare it.
- Add an approved global tool with `mise use -g TOOL`, then review the change
  written directly to `config.toml` in the global checkout.
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

Use only validation that reads files in the checkout by default. Mise config
and task checks must see the repository in a simulated or real
`$MISE_CONFIG_DIR` layout so global file tasks resolve correctly:

```sh
sh -n bootstrap.sh uninstall.sh
mise fmt --all --check
mise tasks validate
git diff --check
```
