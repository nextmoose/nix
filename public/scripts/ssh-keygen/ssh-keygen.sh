#!/bin/sh

echo ssh-keygen -f id-rsa -P "${PASSPHRASE}" -C "" &&
    ssh-keygen -f id-rsa -P "${PASSPHRASE}" -C "" &&
    chmod 0400 id-rsa id-rsa.pub &&
    true
