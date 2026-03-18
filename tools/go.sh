# go — Go programming language (custom download from go.dev API)
TOOL_CMD=go
TOOL_VERSION_ARGS=version

tool_download() {
  command -v curl >/dev/null 2>&1 || { error "curl is required"; return 1; }
  command -v jq >/dev/null 2>&1 || { error "jq is required (install it first)"; return 1; }

  local go_os go_arch
  case "$TOOLS_PLATFORM" in
    aarch64-darwin) go_os="darwin"; go_arch="arm64"  ;;
    aarch64-linux)  go_os="linux";  go_arch="arm64"  ;;
    x86_64-linux)   go_os="linux";  go_arch="amd64"  ;;
    *) error "Unsupported platform: $TOOLS_PLATFORM"; return 1 ;;
  esac

  local jq_filter='
    .[0].files[]
    | select(.os == $os and .arch == $arch and (.filename | endswith($ext)))
    | [.filename, .sha256, .version]
    | @tsv'

  local go_filename go_checksum go_version
  read -r go_filename go_checksum go_version <<< \
    "$(curl -fsSL "https://go.dev/dl/?mode=json" | jq -r \
      --arg os "$go_os" --arg arch "$go_arch" --arg ext "tar.gz" \
      "$jq_filter")"

  if [[ -z "${go_version:-}" || -z "${go_filename:-}" || -z "${go_checksum:-}" ]]; then
    error "No matching stable release found for ${go_os}/${go_arch}"; return 1
  fi

  local state_file="${TOOLS_STATE}/go"
  TOOLS_INSTALL_DIR="${TOOLS_CELLAR}/go/${go_version}"
  TOOLS_INSTALL_TAG="$go_version"
  export TOOLS_INSTALL_DIR TOOLS_INSTALL_TAG

  if [[ -f "$state_file" ]] && [[ "$(cat "$state_file")" == "$go_version" ]] && [[ -d "$TOOLS_INSTALL_DIR" ]]; then
    vlog "skip" "go at ${go_version}"
    TOOLS_INSTALL_SKIPPED=1
    return 0
  fi

  local shasum_cmd
  if command -v shasum >/dev/null 2>&1; then
    shasum_cmd="shasum -a 256 -c"
  elif command -v sha256sum >/dev/null 2>&1; then
    shasum_cmd="sha256sum -c"
  else
    error "shasum or sha256sum is required"; return 1
  fi

  local cache_dir="${TOOLS_CACHE}/go"
  mkdir -p "$cache_dir" "$TOOLS_INSTALL_DIR"

  log "download" "go ${go_version} (${go_os}/${go_arch})"
  curl -fsSL -o "${cache_dir}/${go_filename}" "https://go.dev/dl/${go_filename}"

  log "verify" "checksum"
  echo "${go_checksum}  ${cache_dir}/${go_filename}" | $shasum_cmd >/dev/null 2>&1 || {
    error "Checksum verification failed"
    rm -f "${cache_dir}/${go_filename}"
    return 1
  }

  log "extract" "${go_filename}"
  tar -xzf "${cache_dir}/${go_filename}" -C "$TOOLS_INSTALL_DIR" --strip-components=1

  printf '%s\n' "$go_version" > "$state_file"
  log "install" "go ${go_version} -> ${TOOLS_INSTALL_DIR}"
}

tool_post_install() {
  local current_link="${TOOLS_CELLAR}/go/current"
  ln -sfn "$TOOLS_INSTALL_DIR" "$current_link"
  ln -sf "${TOOLS_INSTALL_DIR}/bin/go" "${XDG_OPT_BIN}/go"
  ln -sf "${TOOLS_INSTALL_DIR}/bin/gofmt" "${XDG_OPT_BIN}/gofmt"
}
