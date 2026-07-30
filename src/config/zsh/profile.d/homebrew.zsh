if [[ -x /opt/homebrew/bin/brew ]]; then
  # Homebrew exists only on macOS hosts in this workstation design.
  export HOMEBREW_DOWNLOAD_CONCURRENCY=auto
  export HOMEBREW_NO_EMOJI=1
  export HOMEBREW_NO_ENV_HINTS=1
  export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1

  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
