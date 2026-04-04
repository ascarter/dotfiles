export FNM_DIR="${FNM_DIR:-${XDG_DATA_HOME}/fnm}"

# Stable path to the fnm default Node.js (no multishell, no subprocess).
# Interactive shell integration (use-on-cd, completions) is in interactive.d.
if [[ -d ${FNM_DIR}/aliases/default/bin ]]; then
  path=(${FNM_DIR}/aliases/default/bin $path)
fi
