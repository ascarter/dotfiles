export RUSTUP_HOME="${XDG_DATA_HOME}"/rustup
export CARGO_HOME="${XDG_DATA_HOME}"/cargo

if [[ -d ${CARGO_HOME}/bin ]]; then
  path=(${CARGO_HOME}/bin $path)
fi

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
