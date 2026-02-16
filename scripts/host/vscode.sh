#!/bin/sh

# Visual Studio Code editor

set -eu

abort() {
  printf '%s\n' "$1" >&2
  exit 1
}

case "$(uname -s)" in
  Darwin)
    echo "Use Homebrew to install Visual Studio Code on macOS"
    echo "brew install --cask visual-studio-code"
    exit 0
    ;;
  Linux)
    : "${XDG_DATA_HOME:="$HOME/.local/share"}"
    : "${XDG_BIN_HOME:="$HOME/.local/bin"}"
    : "${XDG_CACHE_HOME:="$HOME/.cache"}"

    ARCH="$(uname -m)"
    case "$ARCH" in
      x86_64|amd64)
        VSCODE_OS="linux-x64"
        ;;
      aarch64|arm64)
        VSCODE_OS="linux-arm64"
        ;;
      *)
        abort "Unsupported architecture for Visual Studio Code: $ARCH"
        ;;
    esac

    VSCODE_SHA_INDEX_URL="https://code.visualstudio.com/sha"
    VSCODE_DIR="${XDG_DATA_HOME}/vscode"
    VSCODE_BIN="${XDG_BIN_HOME}/code"
    VSCODE_BIN_TARGET="${VSCODE_DIR}/bin/code"
    VSCODE_GUI_BIN="${VSCODE_DIR}/code"
    VSCODE_DESKTOP_DIR="${XDG_DATA_HOME}/applications"
    VSCODE_DESKTOP_FILE="${VSCODE_DESKTOP_DIR}/code.desktop"
    DOWNLOAD_DIR="${XDG_CACHE_HOME}/vscode"
    ARCHIVE_PATH="${DOWNLOAD_DIR}/code-stable-${VSCODE_OS}.tar.gz"
    SHA_PATH="${ARCHIVE_PATH}.sha256"
    STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/vscode-install.XXXXXXXX")"

    command -v jq >/dev/null 2>&1 || abort "jq is required to resolve VS Code download metadata"

    cleanup() {
      rm -rf "${STAGE_DIR}"
    }
    trap cleanup EXIT INT TERM

    install -d "${DOWNLOAD_DIR}" || abort "Failed to create download directory: ${DOWNLOAD_DIR}"
    install -d "${XDG_BIN_HOME}" || abort "Failed to create bin directory: ${XDG_BIN_HOME}"
    install -d "${VSCODE_DESKTOP_DIR}" || abort "Failed to create desktop entry directory: ${VSCODE_DESKTOP_DIR}"

    echo "Resolving Visual Studio Code download metadata..."
    SHA_JSON_PATH="${DOWNLOAD_DIR}/sha.json"
    curl -fLso "${SHA_JSON_PATH}" "${VSCODE_SHA_INDEX_URL}" || abort "Failed to download VS Code SHA index"

    VSCODE_URL="$(
      jq -r --arg os "${VSCODE_OS}" '
        .products[]
        | select(.build == "stable" and .platform.os == $os)
        | .url
      ' "${SHA_JSON_PATH}" | head -n1
    )"
    [ -n "${VSCODE_URL}" ] && [ "${VSCODE_URL}" != "null" ] || abort "Could not resolve stable VS Code URL for ${VSCODE_OS}"

    EXPECTED_SHA="$(
      jq -r --arg os "${VSCODE_OS}" '
        .products[]
        | select(.build == "stable" and .platform.os == $os)
        | .sha256hash
      ' "${SHA_JSON_PATH}" | head -n1
    )"
    [ -n "${EXPECTED_SHA}" ] && [ "${EXPECTED_SHA}" != "null" ] || abort "Could not resolve stable VS Code SHA256 for ${VSCODE_OS}"

    echo "Downloading Visual Studio Code tarball..."
    curl -fLso "${ARCHIVE_PATH}" "${VSCODE_URL}" || abort "Failed to download Visual Studio Code archive"

    printf '%s  %s\n' "${EXPECTED_SHA}" "${ARCHIVE_PATH}" > "${SHA_PATH}.check"

    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum -c "${SHA_PATH}.check" >/dev/null 2>&1 || abort "Checksum verification failed"
    elif command -v shasum >/dev/null 2>&1; then
      ACTUAL_SHA="$(shasum -a 256 "${ARCHIVE_PATH}" | awk '{print $1}')"
      [ "${ACTUAL_SHA}" = "${EXPECTED_SHA}" ] || abort "Checksum verification failed"
    else
      abort "No SHA-256 tool found (need sha256sum or shasum)"
    fi

    echo "Extracting Visual Studio Code..."
    tar -xzf "${ARCHIVE_PATH}" -C "${STAGE_DIR}" || abort "Failed to extract archive"

    # Tarball contains one top-level dir (e.g., VSCode-linux-x64). Install contents directly into VSCODE_DIR.
    TOP_DIR="$(find "${STAGE_DIR}" -mindepth 1 -maxdepth 1 -type d | head -n1)"
    [ -n "${TOP_DIR}" ] || abort "Could not find extracted Visual Studio Code directory"
    [ -x "${TOP_DIR}/code" ] || abort "Extracted package missing 'code' binary"
    [ -x "${TOP_DIR}/bin/code" ] || abort "Extracted package missing 'bin/code' CLI launcher"

    rm -rf "${VSCODE_DIR}"
    install -d "${VSCODE_DIR}" || abort "Failed to create install directory: ${VSCODE_DIR}"
    cp -a "${TOP_DIR}/." "${VSCODE_DIR}/" || abort "Failed to install Visual Studio Code"

    ln -sfn "${VSCODE_BIN_TARGET}" "${VSCODE_BIN}" || abort "Failed to link code CLI"

    cat > "${VSCODE_DESKTOP_FILE}" <<EOF
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=${VSCODE_GUI_BIN} --unity-launch %F
TryExec=${VSCODE_GUI_BIN}
Icon=${VSCODE_DIR}/resources/app/resources/linux/code.png
StartupNotify=true
StartupWMClass=Code
Type=Application
Categories=TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;application/x-code-workspace;
Actions=new-empty-window;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=${VSCODE_GUI_BIN} --new-window %F
Icon=${VSCODE_DIR}/resources/app/resources/linux/code.png
EOF

    echo "Visual Studio Code installed."
    echo "  dir: ${VSCODE_DIR}"
    echo "  cli: ${VSCODE_BIN} -> ${VSCODE_BIN_TARGET}"
    echo "  desktop: ${VSCODE_DESKTOP_FILE}"
    ;;
  *)
    abort "Unsupported operating system: $(uname -s)"
    ;;
esac