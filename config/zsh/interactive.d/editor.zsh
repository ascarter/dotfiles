# Editor preference
if (( $+commands[hx] )); then
  export EDITOR="hx"
elif (( $+commands[vim] )); then
  export EDITOR="vim"
else
  export EDITOR="vi"
fi
