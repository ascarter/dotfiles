# Managed file sources

`config/` mirrors the contents of `$XDG_CONFIG_HOME` and is applied to
`~/.config` with mise's `symlink-each` mode.

This preserves the useful property of the legacy system: managed files can
coexist with local files, editor caches, application state, and configuration
that should not be public.

No root-level home files are currently managed. If that changes, create
`src/home/` and add explicit source-to-target entries in `mise.toml`; do not
assume that all contents of `src/home/` should be linked.

The exception is a managed edit block inside the locally owned `~/.zshenv`.
That block is declared directly in `mise.toml`; it is not a whole-file source.

Git is another intentional split-ownership case. `config/git/config` and
`config/git/ignore` are public sources, while the root `~/.gitconfig` and any
files under the live `~/.config/git/local/` directory remain untracked.

Zed and Neovim follow the same split: public settings live under `config/`,
while downloaded plugins, extensions, language servers, conversations,
credentials, trust decisions, and caches remain in application/XDG state
locations.

Homebrew is a host package manager rather than a dotfile tool, but its global
Brewfile has a native XDG location. `config/homebrew/Brewfile` is therefore
linked to `${XDG_CONFIG_HOME}/homebrew/Brewfile`; macOS host tasks invoke it
with `brew bundle --global`.

Ghostty's public settings and themes live under `config/ghostty/`. Its managed
configuration optionally loads a real, untracked
`${XDG_CONFIG_HOME}/ghostty/local` file after all public settings.

OpenSSH configuration is deliberately absent from `config/`. Tailscale owns
routine SSH authentication, while `~/.ssh/config`, identities, aliases, host
keys, provider paths, known hosts, and agent state remain entirely local.
