# Rust shell configuration
if [ -d ${HOME}/.cargo ]; then
  . "$HOME/.cargo/env"
fi

# Enable shell completions for rustup and cargo
if command -v rustup >/dev/null 2>&1; then
  if [ -n "$BASH_VERSION" ]; then
    eval "$(rustup completions bash)"
    source "$(rustc --print sysroot)"/etc/bash_completion.d/cargo
  elif [ -n "$ZSH_VERSION" ]; then
    eval "$(rustup completions zsh)"
    _cargo_wrapper() {
      source "$(rustc --print sysroot)"/share/zsh/site-functions/_cargo
      _cargo "$@"
    }
    compdef _cargo_wrapper cargo
  fi
fi

# vim: set ft=sh ts=2 sw=2 et:
