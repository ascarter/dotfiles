if [[ -f ${ZDOTDIR}/dircolors ]]; then
  if (( $+commands[uu-dircolors] )); then
    eval "$(uu-dircolors ${ZDOTDIR}/dircolors)"
  elif (( $+commands[dircolors] )); then
    eval "$(dircolors ${ZDOTDIR}/dircolors)"
  fi
fi
