if (( $+commands[dircolors] )) && [[ -f ${ZDOTDIR}/dircolors ]]; then
  eval "$(dircolors ${ZDOTDIR}/dircolors)"
fi
