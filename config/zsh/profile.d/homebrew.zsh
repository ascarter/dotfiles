# Homebrew

export HOMEBREW_NO_EMOJI=1
export HOMEBREW_DOWNLOAD_CONCURRENCY=auto
export HOMEBREW_NO_ENV_HINTS=1

# Prefer app-native updaters for self-updating Homebrew casks.
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1

if [[ -d /opt/homebrew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
