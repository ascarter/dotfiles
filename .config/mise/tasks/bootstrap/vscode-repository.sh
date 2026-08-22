#!/bin/sh
#MISE description="Configure VS Code package repository"

# Configure VS Code package repository

set -eu

if [ "$(uname -s)" != "Linux" ] || [ ! -r /etc/os-release ]; then
  exit 0
fi

. /etc/os-release

configure_apt() {
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
  sudo cat > /etc/apt/sources.list.d/vscode.sources <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
}

configure_dnf() {
  sudo dnf config-manager addrepo \
    --from-repofile=https://packages.microsoft.com/yumrepos/vscode/config.repo \
    --save-filename=vscode
}

case "$ID" in
  fedora)
    configure_dnf
    ;;
  debian | ubuntu)
    configure_apt
    ;;
  *)
    case " ${ID_LIKE:-} " in
      *" debian "* | *" ubuntu "*)
        configure_apt
        ;;
    esac
    ;;
esac
