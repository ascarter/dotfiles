# fnm — fast Node manager
TOOL_CMD=fnm

tool_download() {
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
}

tool_post_install() {
  mkdir -p "${XDG_BIN_HOME}"
  ln -sf "${FNM_DIR}/fnm" "${XDG_BIN_HOME}/fnm"
}
