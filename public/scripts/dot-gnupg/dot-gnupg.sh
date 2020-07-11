#!/bin/sh

gpg --batch --import "${GPG_PRIVATE_KEYS}" &&
    gpg --import-ownertrust "${GPG_OWNERTRUST}" &&
    gpg2 --import "${GPG2_PRIVATE_KEYS}" &&
    gpg2 --import-ownertrust "${GPG2_OWNERTRUST}" &&
    true
