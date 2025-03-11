# Debian/Ubuntu apt
apt_install() {
  if dpkg -l | grep -q -w ${1}; then
    sudo apt-get install --only-upgrade ${1}
  else
    sudo apt-get install ${1}
  fi
}

apt_uninstall() {
  if dpkg -l | grep -q -w ${1}; then
    sudo apt-get purge ${1}
  else
    err "${1} not installed"
  fi
}

ubuntu_reqs() {
  echo "Ubuntu pre-reqs"
}
