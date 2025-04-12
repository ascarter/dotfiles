# 1Password shell configuration

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

# 1Password completions
if [ -n "$BASH_VERSION" ]; then
  source <(op completion bash)
elif [ -n "$ZSH_VERSION" ]; then
  eval "$(op completion zsh)"; compdef _op op
fi

# vim: set ft=sh ts=2 sw=2 et:
