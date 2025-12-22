export RBENV_ROOT="${XDG_DATA_HOME}"/rbenv
export RUBY_CONFIGURE_OPTS="--enable-yjit"
export RV_COLOR=never

# Ruby shell configuration
if (( $+commands[rv] )); then
  eval "$(rv shell init zsh)"
  eval "$(rv shell completions zsh)"
elif (( $+commands[rbenv] )); then
  eval "$(rbenv init -)"
fi
