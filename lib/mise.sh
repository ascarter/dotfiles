# mise
mise_use() {
  if [ -x "$(command -v mise)" ]; then
    dlog "mise use" "$1"
    mise use -g $1
  fi
}

mise_unuse() {
  if [ -x "$(command -v mise)" ]; then
    dlog "mise unuse" "$1"
    mise unuse -g -y $1
  fi
}

mise_upgrade() {
  if [ -x "$(command -v mise)" ]; then
    dlog "mise update" "$1"
    mise upgrade $1
  fi
}

mise_install() {
  if [ ! -x "$(command -v mise)" ]; then
    dlog "installing" "mise"
    curl https://mise.run | sh
  fi

  eval "$(mise activate --shims)"

  dlog "configure" "mise"
  mise set -g MISE_DEFAULT_CONFIG_FILENAME=".mise/config/toml"

  dlog "installing" "mise tools"
  mise use -g usage@latest
  mise use -g ubi:rails/rails-new@latest
}

mise_update() {
  if [ -x "$(command -v mise)" ]; then
    dlog "upgrading" "mise"
    mise self-update
    mise -C ${HOME} up
  fi
}

mise_uninstall() {
  if [ -x "$(command -v mise)" ]; then
    if prompt "Uninstall mise?" ; then
      mise deactivate
      mise implode -y
    fi
  fi
}
