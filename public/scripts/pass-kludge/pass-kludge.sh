#!/bin/sh

read -p "PASSPHRASE" PASSPHRASE &&
    export GPGHOME=$( echo ${PASSWORD_STORE_GPG_OPTS} | cut --fields 2 --delimiter " " ) &&
    echo "${PASSPHRASE}" | gpg --homedir "${GPGHOME}" --batch --pinentry-mode loopback --passphrase-fd 0 decrypt "${PASSWORD_STORE_DIR}/${@}.gpg" &&
    true
