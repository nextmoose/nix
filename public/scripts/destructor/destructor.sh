#!/bin/sh

CLEANER_PROGRAM="${1}" &&
    STRUCTURES_DIR="${2}" &&
    HASH="${3}" &&
    (
	( flock 201 || exit 1 ) &&
	    (
		( flock 202 || exit 1 ) &&
		    cd "${STRUCTURES_DIR}/${HASH}" &&
		    "${CLEANER_PROGRAM}" &&
		    cd "${STRUCTURES_DIR}" &&
		    rm --recursive --force "${STRUCTURES_DIR}/${HASH}" "${STRUCTURES_DIR}/${HASH}.log" "${STRUCTURES_DIR}/${HASH}.out" "${STRUCTURES_DIR}/${HASH}.err" "${STRUCTURES_DIR}/${HASH}.debug" "${STRUCTURES_DIR}/${HASH}.at" &&
		    true
	    ) 202> "${STRUCTURES_DIR}/${HASH}.exclusive" &&
	    rm "${STRUCTURES_DIR}/${HASH}.exclusive" &&
	    true
    ) 201> "${STRUCTURES_DIR}/${HASH}.shared" &&
    rm "${STRUCTURES_DIR}/${HASH}.shared" &&
    true

