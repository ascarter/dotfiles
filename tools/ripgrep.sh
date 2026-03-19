# ripgrep — recursive grep (tarball has a versioned top-level directory)
TOOL_CMD=rg
TOOL_REPO=BurntSushi/ripgrep
TOOL_ASSET_MACOS_ARM64="ripgrep-*-aarch64-apple-darwin.tar.gz"
TOOL_ASSET_LINUX_ARM64="ripgrep-*-aarch64-unknown-linux-gnu.tar.gz"
TOOL_ASSET_LINUX_AMD64="ripgrep-*-x86_64-unknown-linux-musl.tar.gz"
TOOL_STRIP_COMPONENTS=1
TOOL_LINKS=(rg)
TOOL_MAN_PAGES=(doc/rg.1)
TOOL_COMPLETIONS=(complete/_rg complete/rg.bash)
