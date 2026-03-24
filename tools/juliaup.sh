# julia — Julia language (via juliaup version manager)
TOOL_CMD=juliaup
TOOL_TYPE=installer
TOOL_UPGRADE_COMMAND="juliaup self update"
JULIAUP_HOME="${XDG_DATA_HOME}"/juliaup

tool_download() {
  export JULIAUP_DEPOT_PATH="${XDG_DATA_HOME}/julia"
  curl -fsSL https://install.julialang.org | sh -s -- -y --add-to-path=no --path "${JULIAUP_HOME}"
}

tool_uninstall() {
  command -v juliaup >/dev/null 2>&1 && juliaup self uninstall
}
