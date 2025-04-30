export RBENV_ROOT="${XDG_DATA_HOME}/rbenv"
export RUBY_CONFIGURE_OPTS="--enable-yjit"

# Ruby shell configuration
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

# vim: set ft=sh ts=2 sw=2 et:
