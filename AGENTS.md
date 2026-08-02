# Repository instructions

Read `README.md` before changing this repository.

## Scope and ownership

- `.mise/config.toml` owns bootstrap orchestration and the managed `~/.zshenv`
  block.
- `src/config/` mirrors `$XDG_CONFIG_HOME` and is applied with mise
  `symlink-each`; it must coexist with application-owned files.
- `.mise/tasks/bootstrap-git` reconciles the keys it owns in the real, untracked
  `~/.gitconfig`. Unrelated private and work settings remain in that file;
  tokens, signing keys, and other secrets must never enter this repository.
- Do not add global language managers, runtimes, language servers, or build
  tools. Projects introduce them through their own mise and idiomatic version
  files.
- Host packages, desktop applications, system services, fonts, containers,
  Toolbox, and WSL provisioning are outside the current bootstrap scope.

## Safety

- Do not overwrite locally owned files or add private state to this public
  repository.
- Keep bootstrap operations idempotent and show a dry-run before applying.
- Do not install, remove, or modify host packages or services unless the user
  explicitly expands the scope.
- Never inspect or copy private-key or authentication-token contents.

## Validation

Before committing bootstrap changes, run:

```sh
sh -n bootstrap.sh uninstall.sh .mise/tasks/bootstrap-git
mise fmt --check
./bootstrap.sh --dry-run
./uninstall.sh --dry-run
```

The bootstrap dry-run installs mise if it is absent but does not apply the
mise bootstrap plan. The uninstall dry-run must never remove state.
