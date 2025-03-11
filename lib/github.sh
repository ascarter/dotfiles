# GitHub CLI extensions installer
gh_extensions_install() {
  local extensions="github/gh-copilot "

  # Install GitHub CLI extensions
  if [ -x "$(command -v gh)" ]; then
    for extension in $extensions; do
      dlog "installing" "GitHub CLI extension ${extension}"
      gh extension install ${extension}
    done
  fi
}
