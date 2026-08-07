# Apple's built-in FIDO2 security-key provider.
if [[ -f /usr/lib/ssh-keychain.dylib ]]; then
  export SSH_SK_PROVIDER=/usr/lib/ssh-keychain.dylib
fi

