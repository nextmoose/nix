#!/bin/sh

echo "${UUID}" &&
    if [ "${DIGITS}" == 0 ]
    then
	touch pin.asc &&
	    true
    else
	cat /dev/urandom | tr --delete --complement "0-9" | fold --width "${DIGITS}" | head --lines 1 > "${FILE_NAME}" &&
	    true
    fi &&
    chmod 0400 pin.asc &&
    true
