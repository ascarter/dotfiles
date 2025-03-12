# mise
mise_install() {
  dlog "installing" "mise"
  curl https://mise.run | sh
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
      mise implode
    fi
  fi
}
