# Editor preference
if command -v hx >/dev/null 2>&1; then
  export EDITOR="hx"
elif command -v vim >/dev/null 2>&1; then
  export EDITOR="vim"
else
  export EDITOR="vi"
fi

# vim: set ft=sh ts=2 sw=2 et:
