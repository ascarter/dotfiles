install() {
  if command -v rbenv 1>/dev/null 2>&1; then
    echo "rbenv already installed"
    exit 1
  fi

  dlog "rbenv" "installing"
  curl -fsSL https://rbenv.org/install.sh | bash
  rbenv --version
}

uninstall() {
  if ! command -v rbenv 1>/dev/null 2>&1; then
    echo "rbenv not installed"
    exit 1
  fi

  dlog "rbenv" "uninstalling"
  rbenv_root="$(rbenv root)"
  if command -v brew 1>/dev/null 2>&1; then
    brew uninstall rbenv
  fi
  if [ -d "${rbenv_root}" ]; then
    rm -rf "${rbenv_root}"
  fi
}

list() {
  if command -v rbenv 1>/dev/null 2>&1; then
    rbenv --version
  else
    echo "rbenv not installed"
    exit 1
  fi
}
