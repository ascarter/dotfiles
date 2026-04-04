# Go interactive setup (directory creation).
# Exports and PATH are in env.d/go.zsh.
if [[ -x "${GOROOT}/bin/go" ]]; then
  [[ -d ${GOPATH} ]] || mkdir -p "${GOPATH}"
  [[ -d ${GOCACHE} ]] || mkdir -p "${GOCACHE}"
  [[ -d ${GOBIN} ]] || mkdir -p "${GOBIN}"
fi
