#!/bin/sh

if [ "${DIGITS}" == 0 ]
then
    touch "${FILE_NAME}" &&
	true
else
    cat /dev/urandom | tr --delete --complement "0-9" | fold --width "${DIGITS}" | head --lines 1 > "${FILE_NAME}" &&
	true
fi &&
    chmod 0400 "${FILE_NAME}" &&
    true
