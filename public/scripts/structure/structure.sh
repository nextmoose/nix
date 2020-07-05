#!/bin/sh

NOW=$( date +%s ) &&
    if [ ! -d "${STRUCTURES_DIR}" ]
    then
	mkdir "${STRUCTURES_DIR}" &&
	    true
    fi &&
    fun() {
	read GROUPER &&
	    read CLEANER &&
	    HASH=$( echo "${CONSTRUCTOR} ${SALT} ${GROUPER} ${DESTRUCTOR}" | md5sum | cut 1-32  ) &&
	    echo "NOW=${NOW}" >> "${STRUCTURES_DIR}/${HASH}.log" &&
	    if [ -d "${STRUCTURES_DIR}/${HASH}" ]
	    then
		echo "${STRUCTURES_DIR}/${HASH}" &&
		    true
	    else
		mkdir "${STRUCTURES_DIR}/${HASH}" &&
		    cd "${STRUCTURES_DIR}/${HASH}" &&
		    BEFORE=$(date +%s) &&
		    ( "${CONSTRUCTOR}" > "${STRUCTURES_DIR}/${HASH}.out" 2> "${STRUCTURES_DIR}/${HASH}.err" > "${STRUCTURES_DIR}/${HASH}.time" || true ) &&
		    EXIT_CODE="${?}" &&
		    AFTER=$(date +%s) &&
		    (cat > "${STRUCTURES_DIR}/${HASH}.log" <<EOF
NOW=${NOW}
CONSTRUCTOR=${CONSTRUCTOR}
SALT=${SALT}
TIMERS=${TIMERS}
DESTRUCTOR=${DESTRUCTOR}
GROUPER=${GROUPER}
CLEANER=${CLEANER}
EXIT_CODE=${EXIT_CODE}
CONSTRUCTION_TIME=$((${AFTER}-${BEFORE}))
EOF
		    ) &&
		    if [ "${EXIT_CODE}" != 0 ]
		    then
			mkdir "${STRUCTURES_DIR}/${HASH}.${NOW}" &&
			    mv "${STRUCTURES_DIR}/${HASH}" "${STRUCTURES_DIR}/${HASH}.log" "${STRUCTURES_DIR}/${HASH}.out" "${STRUCTURES_+DIR}/${HASH}.err" "${STRUCTURES_DIR}/${HASH}.${NOW}" &&
			    true
		    fi &&
		    at 
		    true
	    fi &&
	    true
    } &&
    "${TIMERS}" "${NOW}" | while fun
    do
	echo fun &&
	    true
    done &&
    true
