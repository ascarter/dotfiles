export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"
export CARGO_HOME="${XDG_DATA_HOME}/cargo"

# Rust shell configuration
if [ -d "${CARGO_HOME}" ]; then
  . "${CARGO_HOME}/env"
fi

# Enable shell completions for rustup and cargo
if command -v rustc >/dev/null 2>&1; then
  if [ -n "$BASH_VERSION" ]; then
    source "$(rustc --print sysroot)"/etc/bash_completion.d/cargo
  elif [ -n "$ZSH_VERSION" ]; then
    _cargo_wrapper() {
      source "$(rustc --print sysroot)"/share/zsh/site-functions/_cargo
      _cargo "$@"
    }
    compdef _cargo_wrapper cargo
  fi
fi
