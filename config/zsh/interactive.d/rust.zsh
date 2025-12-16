export RUSTUP_HOME="${XDG_DATA_HOME}"/rustup
export CARGO_HOME="${XDG_DATA_HOME}"/cargo

# Disable color output from cargo
export CARGO_TERM_COLOR=never

# Rust shell configuration
if [[ -d ${CARGO_HOME} ]]; then
  . "${CARGO_HOME}"/env
fi

# Enable shell completions for rustup and cargo
if (( $+commands[rustup] )); then
  source <(rustup completions zsh)
fi

if (( $+commands[rustc] )); then
  _cargo_wrapper() {
    source "$(rustc --print sysroot)"/share/zsh/site-functions/_cargo
    _cargo "$@"
  }
  compdef _cargo_wrapper cargo
fi
