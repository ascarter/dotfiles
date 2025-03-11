# mise
mise_install() {
  dlog "installing" "mise"
  curl https://mise.run | sh
  eval "$(mise activate --shims)"

  dlog "installing" "dev tools"
  mise -C ${HOME} up
}

mise_update() {
  if [ -x "$(command -v mise)" ]; then
    dlog "upgrading" "mise"
    mise self-update
    mise -C ${HOME} up
  fi
}
