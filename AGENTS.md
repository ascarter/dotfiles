# Repository instructions

This file is the canonical entry point for people and coding agents working in
this repository.

## Read first

1. Read `README.md`.
2. Read `docs/architecture.md`.
3. Before changing ownership or applying configuration, read
   `docs/migration-manifest.md`.
4. For bootstrap behavior, read `docs/bootstrap.md`.
5. Before changing diagnostics or platform detection, read `docs/doctor.md`.
6. Before changing zsh startup behavior, read `docs/shell.md`.
7. Before changing Git ownership or global behavior, read `docs/git.md`.
8. Before changing editor configuration or tool ownership, read
   `docs/editors.md`.
9. Before changing packages, applications, services, fonts, or platform
   detection, read `docs/hosts.md`.
10. Before changing Ghostty settings, themes, or local override behavior, read
   `docs/ghostty.md`.
11. Before changing SSH policy, includes, identity selection, or permissions,
    read `docs/ssh.md`. Never inspect private-key contents.

## Safety

- Treat `/Users/andrew/.local/share/dotfiles` as read-only legacy reference
  material during the migration.
- Do not apply dotfiles, install or remove packages, change login shells,
  alter services, or modify host configuration unless the user explicitly
  requests deployment.
- Prefer status and dry-run commands before any mutating command.
- Do not move or delete the legacy checkout while live symlinks or shell
  startup files still reference it.
- Never place secrets, access tokens, private keys, machine identity, or local
  authentication state in this public repository.

## Design rules

- Use mise's declarative capabilities before adding custom orchestration.
- Keep `host/` for host-specific policy and `src/config/` for XDG
  configuration sources.
- Keep `$HOME` root files locally owned unless a concrete requirement makes
  whole-file management preferable.
- Use mise `symlink-each` for the shared XDG configuration tree.
- Keep Homebrew outside mise tools. Use the official installer and
  `src/config/homebrew/Brewfile` through `brew bundle --global`.
- Use exact, reviewed scripts or manifests for Fedora Atomic RPM overlays.
- Use `flatpak --user` for managed Fedora desktop applications.
- Do not add global language managers or runtimes. Projects introduce their
  own language configuration when needed.
- Project-reproducible formatters, linters, language servers, debuggers, and
  build tools belong in the project. Editor-private installations are
  fallbacks.
- Keep bootstrap steps idempotent and explicitly scoped to host, container, or
  user state.
- Keep `status` and `doctor` read-only, safe before mise is installed, and
  quiet about credentials, identities, SSH details, and Tailscale peers.

## Documentation expectations

- Update the migration manifest when an item changes from `pending` to
  `ported`, `replaced`, or `retired`.
- Document every custom task's ownership boundary and supported environments.
- Explain non-obvious package-channel choices close to their manifest.
- Treat host manifests marked `candidate` as review inputs, not authorization
  to apply them.
- Keep agent instructions about this repository; project-specific language
  instructions belong in those projects.

## Validation

Before proposing deployment:

```sh
./scripts/dotfiles-status
./scripts/dotfiles-doctor
mise fmt --check
mise dotfiles status
mise dotfiles apply --dry-run --verbose
mise bootstrap status --missing
mise bootstrap --dry-run
```

Some commands will remain unavailable until mise is installed. Do not install
it solely to validate a documentation-only change without user approval.
