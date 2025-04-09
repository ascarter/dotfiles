# Enable 1Password SSH agent if installed when running locally
if [ -z "$SSH_TTY" ] && [ -S "${HOME}/.1password/agent.sock" ]; then
  export SSH_AUTH_SOCK="${HOME}/.1password/agent.sock"
fi

# 1Password plugins
if [ -f "${XDG_CONFIG_HOME}/op/plugins.sh" ]; then
  source "${XDG_CONFIG_HOME}/op/plugins.sh"
fi
