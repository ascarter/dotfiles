#!/bin/sh

EMAIL=${1}
AVATAR_DIR=${HOME}/Pictures
HASH=$(echo -n "${EMAIL}" | sha256sum | cut -d ' ' -f 1)
curl -sSL -o avatar --output-dir ${AVATAR_DIR} "https://gravatar.com/avatar/${HASH}?s=256"
FILE_EXT=$(file --extension ${AVATAR_DIR}/avatar | cut -d ':' -f 2 | xargs)
mv ${AVATAR_DIR}/avatar ${AVATAR_DIR}/avatar.${FILE_EXT}
