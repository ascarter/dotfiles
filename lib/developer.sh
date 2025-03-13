# Developer tools

# Go
go_install() {
  dlog "install" "go"
  mise_use go@latest
}

go_update() {
  dlog "update" "go"
  mise_upgrade go
}

go_uninstall() {
  dlog "uninstall" "go"
  mise_unuse go
}

go_list() {
  if [ -x "$(command -v go)" ]; then
    dlog "go" "$(go version)"
  fi
}

# Java
java_install() {
  dlog "install" "java"
  mise_use java@latest
}

java_update() {
  dlog "update" "java"
  mise_upgrade java
}

java_uninstall() {
  dlog "uninstall" "java"
  mise_unuse java
}

java_list() {
  if [ -x "$(command -v java)" ]; then
    dlog "java" "$(java -version)"
  fi
}

# Ruby
ruby_install() {
  dlog "install" "ruby"
  mise_use ruby@latest
}

ruby_update() {
  dlog "update" "ruby"
  mise_upgrade ruby
}

ruby_uninstall() {
  dlog "uninstall" "ruby"
  mise_unuse ruby
}

ruby_list() {
  if [ -x "$(command -v ruby)" ]; then
    dlog "ruby" "$(ruby --version)"
    dlog "gem" "$(gem --version)"
  fi
}

# Rust
rust_install() {
  if [ ! -x "$(command -v rustup)" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --component rust-analyzer
  else
    dlog "exist" "rust"
  fi

  if [[ -d ${HOME}/.cargo ]]; then
    source "$HOME/.cargo/env"
  fi
}

rust_update() {
  if [ -x "$(command -v rustup)" ]; then
    dlog "update" "rust"
    rustup update
  fi
}

rust_uninstall() {
  if [ -x "$(command -v rustup)" ]; then
    dlog "uninstall" "rust"
    rustup self uninstall
  fi
}

rust_list() {
  if [ -x "$(command -v rustc)" ]; then
    dlog "rust" "$(rustc --version)"
    dlog "rustup" "$(RUSTUP_LOG=ERROR rustup --version)"
  fi
}

developer_install() {
  tlog "install" "developer"
  rust_install
  ruby_install
  go_install
}

developer_update() {
  tlog "update" "developer"
  rust_update
  ruby_update
  go_update
}

developer_uninstall() {
  tlog "uninstall" "developer"
  rust_uninstall
  ruby_uninstall
  go_uninstall
}

developer_list() {
  tlog "status" "developer"
  rust_list
  ruby_list
  go_list
}
