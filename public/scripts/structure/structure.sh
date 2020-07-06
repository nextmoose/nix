#!/bin/sh

NOW=$(mktemp -d) &&
    if [ ! -d "${STRUCTURES_DIR}" ]
    then
	mkdir "${STRUCTURES_DIR}" &&
	    true
    fi &&
    fun() {
	read GROUP_TIMESTAMP &&
	    read DESTRUCTION_TIMESTAMP &&
	    SALT=$( ${SALT_PROGRAM} ) &&
	    HASH=$(echo "${CONSTRUCTOR_PROGRAM} ${GROUP_TIMESTAMP} ${SALT} ${CLEANER_PROGRAM}" | md5sum | cut --bytes 1-32) &&
	    if [ ! -d "${STRUCTURES_DIR}/${HASH}.debug" ]
	    then
		mkdir "${STRUCTURES_DIR}/${HASH}.debug" &&
		    true
	    fi &&
	    (
		flock --shared 201 || exit 1
		if [ -d "${STRUCTURES_DIR}/${HASH}" ]
		then
		    echo "NOW=${NOW}" >> "${STRUCTURES_DIR}/${HASH}.log" &&
			echo "${STRUCTURES_DIR}/${HASH}" &&
			true
		else
		    (
			flock --shared 202 || exit 1
			WORK_DIR=$( mktemp -d "${STRUCTURES_DIR}/${HASH}.debug/XXXXXXXX" ) &&
			    mkdir "${WORK_DIR}/${HASH}" &&
			    cd "${WORK_DIR}/${HASH}.tmp" &&
			    BEFORE=$(date +%s) &&
			    ( "${CONSTRUCTOR_PROGRAM}" > "${WORK_DIR}/${HASH}.log" 2> "${WORK_DIR}/${HASH}.err" || true ) &&
			    EXIT_CODE="${?}" &&
			    AFTER=$(date +%s) &&
			    (cat > "${WORK_DIR}/${HASH}.log" <<EOF
CONSTRUCTOR_PROGRAM=${CONSTRUCTOR_PROGRAM}
NOW=${NOW}
TIMES_PROGRAM=${TIMES_PROGRAM}
GROUP_TIMESTAMP=${GROUP_TIMESTAMP}
DESTRUCTION_TIMESTAMP=${DESTRUCTION_TIMESTAMP}
SALT_PROGRAM=${SALT_PROGRAM}
SALT=${SALT}
CLEANING_PROGRAM=${CLEANING_PROGRAM}
EXECUTION_TIME=$((${AFTER}-${BEFORE}))
EOF
			    ) &&
			    if [ "${EXIT_CODE}" == 0 ]
			    then
				D=$(date --date @{DESTRUCTION_TIMESTAMP} +"%H:%M %Y-%m-%d") &&
				    echo "${DESTRUCTOR_PROGRAM} ${CLEANING_PROGRAM} ${HASH}" | at "${D}" &&
				    mv "${WORK_DIR}/${HASH}" "${WORK_DIR}/${HASH}.log" "${WORK_DIR}/${HASH}.out" "${WORK_DIR}/${HASH}.err" "${STRUCTURES_DIR}" &&
				    rm --recursive --force "${WORK_DIR}" &&
				    echo "${STRUCTURES_DIR}/${HASH}" &&
				    true
			    else
				"${CLEANING_PROGRAM}" &&
				    echo "${WORK_DIR}/${HASH}" &&
				    true
			    fi &&
			    true
		    ) 202> "${STRUCTURES_DIR}/${HASH}.lock" &&
			    true
		fi &&
		    true
	    ) 201> "${STRUCTURES_DIR}/${HASH}.lock" &&
	    true
    } &&
    "${TIMERS_PROGRAM}" | fun
