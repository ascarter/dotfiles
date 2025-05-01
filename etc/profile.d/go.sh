export GOPATH="${XDG_STATE_HOME}/go"
# export GOBIN="${HOME}/.local/bin"
export GOMODCACHE="${XDG_CACHE_HOME}/go/mod"

if command -v go >/dev/null 2>&1; then
  export PATH=$(go env GOPATH)/bin:$PATH
fi

# vim: set ft=sh ts=2 sw=2 et:
