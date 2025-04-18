#!/bin/sh

set -eu

install() {
  # Ruby
  if ! command -v rbenv >/dev/null 2>&1; then
    echo "Configuring Ruby (rbenv)"
    curl -fsSL https://rbenv.org/install.sh | bash
  #eval "$($RBENV_ROOT/bin/rbenv init - --no-rehash sh)"
  else
    info
  fi
}

uninstall() {
  if command -v rbenv >/dev/null 2>&1; then
    rm -rf "$(rbenv root)"
  fi

  if command -v brew >/dev/null 2>&1; then
    brew uninstall rbenv ruby-build
  fi
}

info() {
  if command -v rbenv >/dev/null 2>&1; then
    rbenv --version
    echo "RBENV_ROOT=$(rbenv root)"
    rbenv versions
  else
    echo "rbenv is not installed."
  fi
}

doctor() {
  if command -v rbenv >/dev/null 2>&1; then
    curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-doctor | bash
  else
    echo "rbenv is not installed."
  fi
}
