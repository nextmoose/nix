#!/bin/sh

ssh-keygen -f ./id-rsa.asc -p "${PASSPHRASE}" -C "" &&
    true
