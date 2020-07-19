#!/bin/sh

ssh-keygen -f ./id-rsa.asc -P "${PASSPHRASE}" -C "" &&
    true
