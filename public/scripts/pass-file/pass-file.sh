#!/bin/sh

export PASSWORD_STORE_GPG_OPTS="--homedir ${DOT_GNUPG}" &&
    pass show "${PASS_NAME}" > "${FILE_NAME}" &&
    chmod 0400 "${FILE_NAME}" &&
    chmod 0700 "$( pwd )" &&
    true
