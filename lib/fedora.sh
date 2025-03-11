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

fedora_reqs() {
  echo "Fedora pre-reqs"
  dnf_install dnf-plugins-core
}
