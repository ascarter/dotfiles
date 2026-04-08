# lib/checksum.sh — portable SHA-256 file verification
#
# Sourced by scripts that need checksum verification.
# No shebang — this file is sourced, not executed.
#
# Provides: sha256_verify
#
# Usage:
#   source "${DOTFILES_HOME}/lib/checksum.sh"
#   sha256_verify /path/to/file "expected_hex_digest"
#   # returns 0 on match, 1 on mismatch

# Idempotent guard
[[ -n "${_DOTFILES_CHECKSUM_LOADED:-}" ]] && return 0
_DOTFILES_CHECKSUM_LOADED=1

# Detect available SHA-256 tool (once at source time)
if command -v sha256sum >/dev/null 2>&1; then
  _SHA256_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  _SHA256_CMD="shasum"
else
  abort "No SHA-256 tool found (need sha256sum or shasum)"
fi

# sha256_verify <file> <expected_hex_digest>
# Returns 0 on match, 1 on mismatch.
sha256_verify() {
  local file="$1" expected="$2"
  case "$_SHA256_CMD" in
    sha256sum)
      echo "${expected}  ${file}" | sha256sum -c - >/dev/null 2>&1
      ;;
    shasum)
      echo "${expected}  ${file}" | shasum -a 256 -c - >/dev/null 2>&1
      ;;
  esac
}
