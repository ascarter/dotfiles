uninstall() {
  local rbenv_dir="${1}/.rbenv"
  if [ -d "${rbenv_dir}" ]; then
    rm -rf "${rbenv_dir}"
  fi
}

uninstall ${TARGET}
