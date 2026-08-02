# dotfiles

Portable, XDG-based development configuration built around
[mise](https://mise.jdx.dev/).

## Current scope

- Apply the public configuration under `src/config/` to `~/.config`.
- Maintain a small managed block in `~/.zshenv` for XDG locations and
  `ZDOTDIR`, while leaving the rest of that file locally owned.
- Make `/bin/zsh` the login shell.
- Install `gh` and Git LFS globally through mise.
- Reconcile a private, untracked `~/.gitconfig` with Git identity, GitHub HTTPS
  authentication, optional Azure DevOps GCM support, Git LFS filters, and the
  applicable host diff/merge tool. Private and work-specific Git settings also
  live in this file; commit signing is deliberately deferred.
- Keep language managers, runtimes, language servers, and build tools in their
  projects rather than the global mise configuration.

Host packages and applications are deliberately deferred. This bootstrap does
not invoke Homebrew, rpm-ostree, Flatpak, or platform-specific provisioning.

## Bootstrap

The bootstrap requires `curl`, `git`, and `/bin/zsh`. From an existing clone:

```sh
./bootstrap.sh
```

Once this repository is published at its canonical public URL, a new
workstation can use:

```sh
curl -fsSL https://raw.githubusercontent.com/ascarter/dotfiles/main/bootstrap.sh | sh
```

The script installs mise at `~/.local/bin/mise`, clones the repository into
`~/Developer/dotfiles` when needed, trusts the repository configuration, and
always shows a dry-run before asking to apply. Use `./bootstrap.sh --dry-run`
for preview only.

## Uninstall

The partner uninstall script first previews every removal:

```sh
./uninstall.sh --dry-run
./uninstall.sh
```

It uses mise's dotfile unapply operation to remove the configured XDG links
and managed `.zshenv` block, removes GitHub credential-helper entries only
when they point exclusively to mise-managed `gh`, and then runs
`mise implode` to remove mise, its installed tools, and its data. An empty
`~/.config/mise` directory is removed; any remaining local configuration is
preserved.

The script deliberately preserves this repository, GitHub authentication
data, local Git configuration, and the `/bin/zsh` login shell.
It cannot infer a previous login shell safely. Start a fresh login session
after uninstalling because the current process retains its existing shell
environment.

## Layout

```text
.
├── AGENTS.md
├── .mise/
│   ├── config.toml         # repository-local mise configuration
│   └── tasks/
│       └── bootstrap-git   # local Git/GitHub readiness
├── bootstrap.sh
├── uninstall.sh
└── src/
    └── config/             # source for ~/.config via mise symlink-each
```

`src/config/` deliberately mirrors the contents of `$XDG_CONFIG_HOME`, not the
repository root. Mise maps it explicitly to `~/.config` using `symlink-each`,
which allows local and application-owned files to coexist.

There are currently no managed files at the root of `$HOME`. If one is ever
needed, its source will live under `src/home/` and receive an explicit
`[dotfiles]` entry. The bootstrap instead uses a managed block inside the
locally owned `~/.zshenv`, not a whole-file link.

The aggregate `bootstrap` task runs the `bootstrap-git` FileTask on every
invocation. It is intentionally idempotent: it preserves an existing GitHub
login, derives identity from that account, and lets `gh` and Git LFS reconcile
their own settings in the real `~/.gitconfig`. The task updates only the keys
it owns, so unrelated private and work settings in that file are preserved.

Reconcile Git configuration explicitly after installing GCM, changing an
identity, or upgrading an owning tool:

```sh
mise run bootstrap-git
DOTFILES_GIT_NAME="Your Name" \
  DOTFILES_GIT_EMAIL="you@example.com" \
  mise run bootstrap-git
```

## Change lifecycle

Treat this repository as the source of truth and use the same cycle for every
change:

```text
edit source → preview → apply or install → verify → commit
```

Work from `~/Developer/dotfiles` unless a command says otherwise. Prefer the
narrow commands below for routine maintenance; use `./bootstrap.sh` when
reconciling the complete workstation configuration.

### Edit an existing dotfile

Files already managed with `symlink-each` are live symlinks. Editing a source
such as `src/config/ghostty/config` changes the active file immediately, so no
apply step is required for content-only changes:

```sh
$EDITOR src/config/ghostty/config
mise bootstrap dotfiles status --missing
git diff -- src/config/ghostty/config
```

Edit the repository path rather than the live `~/.config` path so ownership is
clear. Some applications save by replacing a symlink with a regular file;
`mise bootstrap dotfiles status` detects that drift.

### Add a dotfile

Create the source beneath `src/config/`, following its intended XDG path. The
existing directory-wide `symlink-each` mapping discovers new files, so adding
an application does not require another entry in `.mise/config.toml`.

New files are not linked until dotfiles are applied:

```sh
mise bootstrap dotfiles apply --dry-run
mise bootstrap dotfiles apply --yes
mise bootstrap dotfiles status --missing
```

Mise refuses to replace a conflicting real file by default. Inspect and
resolve the conflict deliberately rather than routinely using `--force`.

### Change the managed `.zshenv` block

The desired XDG and `ZDOTDIR` block lives in `.mise/config.toml`; it is an edit
inside a locally owned file rather than a symlink. After changing it:

```sh
mise bootstrap dotfiles apply --dry-run
mise bootstrap dotfiles apply --yes
exec /bin/zsh -l
```

Mise updates only the marker-delimited block and preserves local content
outside it.

### Add a global tool

Add the tool to `[tools]` in `src/config/mise/config.toml`. Because the global
mise configuration is already linked, the declaration becomes active
immediately; install the requested binary explicitly. For example, after
adding `jq = "latest"`:

```sh
mise install --dry-run jq
mise install jq
mise ls jq
```

Use `mise upgrade gh` to check for and install a newer release of an existing
floating tool such as `gh = "latest"`.

Removing a tool from `[tools]` stops selecting it but does not immediately
delete its installed versions. Cleanup is a separate, deliberate operation:

```sh
mise ls --prunable
mise prune --dry-run --tools
```

Run `mise prune --tools` only after reviewing the dry-run.

### Delete or rename a dotfile

Mise dotfile application is additive and keeps no ownership database. Removing
a source does not remove the old live target. For a deletion or rename:

1. Remove or rename the repository source.
2. Verify the old live target is a symlink into this repository.
3. Remove that old target manually.
4. Preview and apply dotfiles.
5. Verify the resulting state before committing.

### Commit the result

After the focused verification succeeds, review and stage only the intended
paths:

```sh
git diff --check
git status --short
git add path/to/changed-source
git diff --cached
git commit -m "Describe the configuration change"
```

Do not commit secrets, tokens, private keys, host identity, or machine-local
authentication state. A new workstation receives the committed state through
`bootstrap.sh`; an existing workstation can usually apply only the component
that changed.
