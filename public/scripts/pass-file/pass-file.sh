#!/bin/sh

export PASSWORD_STORE_GPG_OPTS="--homedir ${DOT_GNUPG}" &&
    pass show "${PASS_NAME}" > secret.asc &&
#    chmod 0400 secret.asc &&
    chmod 0700 "$( pwd )" &&
    true
