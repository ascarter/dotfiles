# GitHub CLI shell configuration

if [[ -o interactive ]] && (( $+commands[gh] )); then
  eval "$(gh completion -s zsh)"

  if gh extension list 2>/dev/null | grep -q gh-tool; then
    eval "$(gh tool shell zsh)"

    # Wire gh-tool subcommand completion into _gh.
    # gh's completion discovers extensions but cannot complete their subcommands.
    # Source the cobra-generated completion, then intercept 'gh tool ...'
    # and delegate to _gh-tool with the real extension binary path.
    typeset -g _GH_TOOL_BIN="${XDG_DATA_HOME:-$HOME/.local/share}/gh/extensions/gh-tool/gh-tool"
    if [[ -x "$_GH_TOOL_BIN" ]]; then
      eval "$(gh tool completion zsh 2>/dev/null)"
      functions[_gh_without_extensions]="${functions[_gh]}"
      _gh() {
        if (( CURRENT > 2 )) && [[ "${words[2]}" == "tool" ]]; then
          words=("$_GH_TOOL_BIN" "${words[3,-1]}")
          (( CURRENT-- ))
          _gh-tool
          return
        fi
        _gh_without_extensions "$@"
      }
    fi
  fi
fi
