# 1Password CLI plugins
op_plugins_install() {
  local plugins="gh"

  # Init 1Password CLI plugins
  if [ -x "$(command -v op)" ]; then
    for plugin in $plugins; do
      if [ -x "$(command -v op)" ]; then
        dlog "init" "1Password CLI plugin ${plugin}"
        op plugin init ${plugin}
      fi
    done
  fi

  # Configure 1P SSH
  if [ -S ${HOME}/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ] && ! [ -L ~/.1password/agent.sock ]; then
    dlog "link" "~/.1password/agent.sock"
    mkdir -p ~/.1password
    ln -s ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ~/.1password/agent.sock
  fi

  if [ -L ~/.1password/agent.sock ]; then
    if ! [ -f ~/.ssh/config ] || ! grep -q -x "Include ~/.config/ssh/config" ~/.ssh/config; then
      dlog "enable" "SSH IdentityAgent"
      mkdir -p ~/.ssh
      echo "Include ~/.config/ssh/config" >>~/.ssh/config
    else
      dlog "exists" "SSH IdentityAgent"
    fi
  fi
}
