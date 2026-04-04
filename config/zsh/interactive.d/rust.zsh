# Rust interactive setup (completions).
# Exports and PATH are in env.d/rust.zsh.
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
