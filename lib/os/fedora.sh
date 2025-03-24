# Fedora/RHEL dnf
dnf_install() {
  if rpm -q ${1}; then
    action=upgrade
  else
    action=install
  fi

  sudo dnf ${action} -y ${1}
}

dnf_uninstall() {
  if rpm -q ${1}; then
    sudo dnf remove -y ${1}
  else
    err "${1} not installed"
  fi
}

dnf_config_manager() {
  sudo dnf config-manager --add-repo ${1}
}

os_install() {
  dnf_install dnf-plugins-core
  dnf_install @development-tools
  dnf_install curl
  dnf_install git
  dnf_install zsh

  # Change default shell to zsh
  sudo usermod -s /usr/bin/zsh ${USER}

  brew_install
  brew_update
}

os_update() {
  sudo dnf update -y
  brew_update
}

os_uninstall() {
  brew_uninstall
}
