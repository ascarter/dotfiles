# macOS
xcode_install() {
  if ! [ -e /Library/Developer/CommandLineTools ]; then
    dlog "install" "xcode"
    xcode-select --install
    read -p "Press [Enter] to continue..." -n1 -s
    echo
    sudo xcodebuild -runFirstLaunch
  else
    dlog "exists" "xcode"
  fi

  # Enable developer mode
  spctl developer-mode enable-terminal
}

os_install() {
  xcode_install
  brew_install
  brew_update
}

os_update() {
  brew_update
}

os_uninstall() {
  brew_uninstall
}
