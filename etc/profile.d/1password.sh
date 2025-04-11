# 1Password shell configuration

# Configure gh copilot aliases before enabling 1Password
# Otherwise will have to authorize for every new terminal
if command -v gh &> /dev/null; then
  [ -n "$ZSH_VERSION" ] && eval "$(gh copilot alias -- zsh)"
  [ -n "$BASH_VERSION" ] && eval "$(gh copilot alias -- bash)"
fi

# Enable 1Password SSH agent if installed when running locally
if [ -z "$SSH_TTY" ] && [ -S "${HOME}/.1password/agent.sock" ]; then
  export SSH_AUTH_SOCK="${HOME}/.1password/agent.sock"
fi

# 1Password cli in toolbox
if [ -f /run/.containerenv ] && [ -d /run/host/opt/1Password ]; then
  alias op=/run/host/bin/op
  alias op-ssh-sign=/run/host/opt/1Password/op-ssh-sign
fi

# 1Password plugins
if [ -f "${XDG_CONFIG_HOME}/op/plugins.sh" ]; then
  source "${XDG_CONFIG_HOME}/op/plugins.sh"
fi

# vim: set ft=sh ts=2 sw=2 et:
