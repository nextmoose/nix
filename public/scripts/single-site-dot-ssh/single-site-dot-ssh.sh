#!/bin/sh

sed \
    -e "s#\${HOST}#${HOST}#" \
    -e "s#\${HOST_NAME}#${HOST_NAME}#" \
    -e "s#\${USER}#${USER}#" \
    -e "s#\${PORT}#${PORT}#" \
    -e "s#\${IDENTITY_FILE}#${IDENTITY_FILE}#" \
    -e "s#\${USER_KNOWN_HOSTS_FILE}#${USER_KNOWN_HOSTS_FILE}#" \
    -e "s#\${DOT_SSH}#$(pwd)#" \
    -e "wconfig" \
    "${STORE_DIR}/src/config" &&
    chmod 0400 "config" &&
    chmod 0700 $(pwd) &&
    true
