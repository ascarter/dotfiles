# Developer tools

# Go
go_install() {
  mise use -g go@latest
}

go_update() {
  mise upgrade go
}

go_uninstall() {
  mise unuse -g go@latest
}

# Java
java_install() {
  mise use -g java@latest
}

java_update() {
  mise upgrade java
}

java_uninstall() {
  mise unuse -g java@latest
}

# Ruby
ruby_install() {
  mise use -g ruby@latest
}

ruby_update() {
  mise upgrade ruby
}

ruby_uninstall() {
  mise unuse -g ruby@latest
}

# Rust
rust_install() {
  if [ ! -x "$(command -v rustup)" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --component rust-analyzer
  fi
}

rust_update() {
  if [ -x "$(command -v rustup)" ]; then
    rustup update
  fi
}

rust_uninstall() {
  if [ -x "$(command -v rustup)" ]; then
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
