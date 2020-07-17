#!/bin/sh

read -p "PASSPHRASE" PASSPHRASE &&
    
    echo "${PASSPHRASE}" | gpg --batch --pinentry-mode loopback --passphrase-fd 0 decrypt "${PASSWORD_STORE_DIR}/${@}.gpg" &&
    true
