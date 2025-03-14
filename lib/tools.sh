# 1Passowrd CLI
op_install() {
  dlog "install" "1Password CLI"

  plugins=(
    gh
  )

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

# GitHub CLI extensions installer
gh_install() {
  extensions=(
    github/gh-copilot
  )

  if [ -x "$(command -v gh)" ]; then
    for extension in $extensions; do
      dlog "installing" "GitHub CLI extension ${extension}"
      gh extension install ${extension}
    done
  fi
}

# Generate completions
update_completions() {
  completion_dir="${1:-$HOME/.local/share/zsh/functions}"
  tools=(
    docker
    rustup
    cargo
  )
  tool_cmds=(
    "docker completion zsh"
    "rustup completions zsh"
    "rustup completions zsh cargo"
  )

  mkdir -p ${completion_dir}
  tlog "update" "completions"

  for i in "${!tools[@]}"; do
    tool="${tools[$i]}"
    tool_cmd="${tool_cmds[$i]}"
    tool_completion="_${tool}"

    if command -v ${tool} >/dev/null 2>&1; then
      dlog "completion" "${tool}"
      eval "${tool_cmd}" > "${completion_dir}/${tool_completion}"
    else
      dlog "missing" "${tool}"
    fi
  done
}

tools_install() {
  op_install
  gh_install
}

tools_update() {
}

tools_uninstall() {
}
