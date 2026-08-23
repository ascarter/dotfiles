#!/bin/sh
#MISE description="Configure Linux package repositories"

set -eu

if [ "$(uname -s)" != "Linux" ] || [ ! -r /etc/os-release ]; then
  exit 0
fi

. /etc/os-release

configure_apt() {
  # vscode
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
  sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
  sudo dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

  if ! dnf repo list --json vscode-yum | jq -e 'length > 0' >/dev/null; then
    sudo dnf config-manager addrepo --from-repofile=https://packages.microsoft.com/yumrepos/vscode/config.repo --save-filename=vscode
  fi
}

configure_flatpak() {
  command -v flatpak >/dev/null 2>&1 || return 0
  flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak remote-add --user --if-not-exists cosmic https://apt.pop-os.org/cosmic/cosmic.flatpakrepo
}

case "$ID" in
  fedora)
    configure_dnf
    configure_flatpak
    ;;
  debian | ubuntu)
    configure_apt
    configure_flatpak
    ;;
  *)
    case " ${ID_LIKE:-} " in
      *" debian "* | *" ubuntu "*)
        configure_apt
        ;;
    esac
    configure_flatpak
    ;;
esac
