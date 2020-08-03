#!/bin/sh

if [ ! -f "${PASSWORD_STORE_DIR}/.gpg-id" ]
then
    pass git fetch personal "${STARTER_BRANCH}" &&
	pass git checkout "personal/${STARTER_BRANCH}" .gitattributes &&
	pass git checkout "personal/${STARTER_BRANCH}" .gpg-id &&
	pass git checkout -b "${NEW_BRANCH}" &&
	pass git push personal HEAD &&
	true
fi &&
    true
