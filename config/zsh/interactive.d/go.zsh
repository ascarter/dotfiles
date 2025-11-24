export GOPATH="${XDG_DATA_HOME}"/go
export GOBIN="${XDG_BIN_HOME}"
export GOCACHE="${XDG_CACHE_HOME}"/go-build
export GOENV="${XDG_CONFIG_HOME}"/go/env

if (( $+commands[go] )); then
  [[ -d ${GOPATH} ]] || mkdir -p "${GOPATH}"
  [[ -d ${GOCACHE} ]] || mkdir -p "${GOCACHE}"
  [[ -d ${GOBIN} ]] || mkdir -p "${GOBIN}"
  path=($GOBIN $path)
fi
