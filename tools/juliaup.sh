# julia — Julia language (via juliaup version manager)
TOOL_CMD=juliaup
TOOL_TYPE=installer
TOOL_UPGRADE_COMMAND="juliaup self update"
JULIAUP_HOME="${XDG_DATA_HOME}/juliaup"
JULIAUP_DEPOT_PATH="${XDG_DATA_HOME}/julia"
TOOL_INSTALL_URL="https://install.julialang.org"
TOOL_INSTALL_ENV="JULIAUP_DEPOT_PATH=${JULIAUP_DEPOT_PATH}"
TOOL_INSTALL_ARGS="-y --add-to-path=no --path ${JULIAUP_HOME}"
TOOL_UNINSTALL_COMMAND="juliaup self uninstall"
TOOL_UNINSTALL_PATHS=("${JULIAUP_HOME}" "${JULIAUP_DEPOT_PATH}")
