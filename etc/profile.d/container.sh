# Container environment configuration

# Apple container runtime
if command -v container >/dev/null 2>&1; then
  if [ -n "$BASH_VERSION" ]; then
    eval "$(container --generate-completion-script bash)"
  elif [ -n "$ZSH_VERSION" ]; then
    _container_wrapper() {
      eval "$(container --generate-completion-script zsh)"
      _container "$@"
    }
    compdef _container_wrapper container
  fi
fi
