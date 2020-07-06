#!/bin/sh

DESTRUCTOR="${1}" &&
    HASH="${2}" &&
    cd "${STRUCTURES_DIR}/${HASH}" &&
    (flock 203 || exit 1
     "${CLEANING_PROGRAM}" &&
	 cd / &&
	 rm --recursive --force "${STRUCTURES_DIR}/${HASH} ${STRUCTURES_DIR}/${HASH}.log ${STRUCTURES_DIR}/${HASH}.out ${STRUCTURES_DIR}/${HASH}.err ${STRUCTURES_DIR}/${HASH}.debug" &&
	 true
    ) 203>  "${STRUCTURES_DIR}/${HASH}.lock" &&
    rm "${STRUCTURES_DIR}/${HASH}.lock" &&
    if [ -z "$(find ${STRUCTURES_DIR} -mindepth 1)" ]
    then
	rm --recursive --force "${STRUCTURES_DIR}" &&
	    true
    fi &&
    true
