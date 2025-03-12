# Developer tools

# Go
go_install() {
  dlog "install" "go"
  mise use -g go@latest
}

go_update() {
  dlog "update" "go"
  mise upgrade go
}

go_uninstall() {
  dlog "uninstall" "go"
  mise unuse -g go@latest
}

# Java
java_install() {
  dlog "install" "java"
  mise use -g java@latest
}

java_update() {
  dlog "update" "java"
  mise upgrade java
}

java_uninstall() {
  dlog "uninstall" "java"
  mise unuse -g java@latest
}

# Ruby
ruby_install() {
  dlog "install" "ruby"
  mise use -g ruby@latest
}

ruby_update() {
  dlog "update" "ruby"
  mise upgrade ruby
}

ruby_uninstall() {
  dlog "uninstall" "ruby"
  mise unuse -g ruby@latest
}

# Rust
rust_install() {
  if [ ! -x "$(command -v rustup)" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --component rust-analyzer
  else
    dlog "exist" "rust"
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
