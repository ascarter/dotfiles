# julia — Julia language (via juliaup version manager)
TOOL_CMD=juliaup

tool_download() {
  export JULIAUP_DEPOT_PATH="${XDG_DATA_HOME}/julia"
  curl -fsSL https://install.julialang.org | sh -s -- \
    -y \
    --add-to-path=no \
    --background-selfupdate=0 \
    --startup-selfupdate=0 \
    --path "${XDG_OPT_HOME}/juliaup"
}

tool_post_install() {
  local juliaup_bin="${XDG_OPT_HOME}/juliaup/bin"
  for bin in juliaup julia julialauncher; do
    [[ -f "${juliaup_bin}/${bin}" ]] || continue
    ln -sf "${juliaup_bin}/${bin}" "${XDG_OPT_BIN}/${bin}"
  done
}

tool_upgrade() {
  juliaup self update
}

tool_uninstall() {
  command -v juliaup >/dev/null 2>&1 && juliaup self uninstall -y
  rm -f "${XDG_OPT_BIN}/juliaup" "${XDG_OPT_BIN}/julia" "${XDG_OPT_BIN}/julialauncher"
  rm -rf "${XDG_OPT_HOME}/juliaup"
}
