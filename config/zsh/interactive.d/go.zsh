export GOPATH="${XDG_STATE_HOME}"/go
export GOROOT="${GOROOT:-${XDG_DATA_HOME}/go}"
export GOMODCACHE="${XDG_CACHE_HOME}"/go/mod

# Add Go binaries to PATH
if [[ -d ${GOROOT}/bin ]]; then
  path=("${GOROOT}/bin" $path)
fi

if (( $+commands[go] )); then
  path=($(go env GOPATH)/bin $path)
fi
