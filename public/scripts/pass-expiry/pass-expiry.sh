#!/bin/sh

NOW=$( date +%s ) &&
    YEAR=$( date --date @${NOW} +%Y ) &&
    pass git ls-tree --name-only --full-tree HEAD | grep "[.]gpg\$" | sed -e "s#[.]gpg\$##" | while read PASS_NAME
    do
	FILE_NAME="${PASS_NAME}.gpg" &&
	    PASS_LENGTH="$( pass show "${PASS_NAME}" | tr -d "\n" | wc --bytes )" &&
	    COMMIT_TIME=$( pass git log --max-count 1 --format=%ct -- "${FILE_NAME}" ) &&
	    AGE=$(( ${NOW} - ${COMMIT_TIME} )) &&
	    if [ "${AGE}" -gt $(( 60 * 60 * 24 * 7 * 4 * 3 )) ]
	    then
		echo "${PASS_NAME}" &&
		    true
	    elif [ "${PASS_LENGTH}" -lt "${YEAR}" ]
	    then
		echo "${PASS_NAME}" &&
		    true
	    fi &&
	    true
    done &&
    true
