#!/bin/sh

# Ruby toolchain management via rbenv

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
RBENV_ROOT="${RBENV_ROOT:-${XDG_DATA_HOME}/rbenv}"
RUBY_CONFIGURE_OPTS="--enable-yjit"

log() {
  if [ "$#" -eq 1 ]; then
    printf "%s\n" "$1"
  elif [ "$#" -gt 1 ]; then
    printf "$(tput bold)%-10s$(tput sgr0)\t%s\n" "$1" "$2"
  fi
}

latest() {
  # Verify rustc is available
  if ! command -v rustc >/dev/null 2>&1; then
    log "ruby-build" "rustc is required to build Ruby with YJIT support"
    return 1
  fi

  # Verify rbenv available
  if [ -d "${RBENV_ROOT}" ] && command -v "${RBENV_ROOT}/bin/rbenv" >/dev/null 2>&1; then
    eval "$(${RBENV_ROOT}/bin/rbenv init -)"

    # Install latest Ruby and enable YJIT
    ruby_ver=$(rbenv install --list | grep -E '^[0-9].[0-9]+.[0-9]+' | sort -V | tail -n 1)

    if ! rbenv versions | grep $ruby_ver; then
      log "ruby-build" "installing latest Ruby version: $ruby_ver"
      rbenv install $ruby_ver
    else
      log "ruby-build" "latest Ruby version $ruby_ver already installed"
    fi
  else
    log "ruby" "rbenv not installed, cannot install latest Ruby"
    return 1
  fi
}

install() {
  # Check if rbenv is already installed
  if [ -d "${RBENV_ROOT}" ] && command -v "${RBENV_ROOT}/bin/rbenv" >/dev/null 2>&1; then
    log "rbenv" "already installed, skipping"
  else
    if ! command -v git >/dev/null 2>&1; then
      log "ruby" "git is required for installation"
      return 1
    fi

    log "ruby" "installing rbenv with git to ${RBENV_ROOT}"

    # Install rbenv
    mkdir -p "${RBENV_ROOT}"
    cd "${RBENV_ROOT}"
    git init
    git remote add -f -t master origin https://github.com/rbenv/rbenv.git
    git checkout -b master origin/master

    # Install ruby-build plugin
    mkdir -p "${RBENV_ROOT}/plugins"
    git clone https://github.com/rbenv/ruby-build.git "${RBENV_ROOT}/plugins/ruby-build"

    # Enable caching of rbenv-install downloads
    mkdir -p "${RBENV_ROOT}/cache"
  fi

  # Install most current Ruby
  latest

  log "ruby" "rbenv installed successfully"
}

update() {
  if [ ! -d "${RBENV_ROOT}" ]; then
    log "ruby" "not installed"
    return 1
  fi

  log "ruby" "updating rbenv and ruby-build"

  # Update rbenv
  cd "${RBENV_ROOT}"
  if git remote -v 2>/dev/null | grep -q rbenv; then
    git pull --tags origin master
  fi

  # Update ruby-build plugin
  if [ -d "${RBENV_ROOT}/plugins/ruby-build" ]; then
    cd "${RBENV_ROOT}/plugins/ruby-build"
    if git remote -v 2>/dev/null | grep -q ruby-build; then
      git pull origin master
    fi
  fi

  # Install most current Ruby
  latest
}

uninstall() {
  if [ -d "${RBENV_ROOT}" ]; then
    log "ruby" "removing rbenv installation"
    rm -rf "${RBENV_ROOT}"
  else
    log "ruby" "already uninstalled"
  fi
}

status() {
  if [ -d "${RBENV_ROOT}" ] && [ -x "${RBENV_ROOT}/bin/rbenv" ]; then
    local current_version
    current_version=$("${RBENV_ROOT}/bin/rbenv" version-name 2>/dev/null || echo "none")
    log "ruby" "rbenv installed, current: ${current_version}"
  else
    log "ruby" "not installed"
  fi
}

# Handle command line arguments
action="${1:-status}"
case "${action}" in
install | update | uninstall | status)
  "${action}"
  ;;
*)
  echo "Usage: $0 {install|update|uninstall|status}" >&2
  exit 1
  ;;
esac
