#!/bin/sh

set -eu

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

case $(uname -s) in
Darwin)
  brew install --cask docker
  ;;
Linux)
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Docker not yet supported on ${ID}${VARIANT_ID:+-$VARIANT_ID}"
  else
    echo "linux-unknown"
  fi
  ;;
*) echo "unknown" ;;
esac

# Generate completions
if command -v docker > /dev/null 2>&1; then
  echo "Generate completion for docker"
  completion_dir="${HOME}/.local/share/zsh/functions"
  mkdir -p "${completion_dir}"
  docker completion zsh > "${completion_dir}/_docker"
fi