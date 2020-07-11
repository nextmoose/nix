#!/bin/sh

NOW=$( date +%s ) &&
    if [ ! -d "${STRUCTURES_DIR}" ]
    then
	mkdir "${STRUCTURES_DIR}" &&
	    true
    fi &&
    SALT="$( ${SALT_PROGRAM} )" &&
    SCHEDULED_DESTRUCTION_TIME=$( date --date @$(( ( ( $( date +%s ) + ${SECONDS} ) / ${SECONDS} ) * ${SECONDS} )) +%s ) &&
    HASH=$( ( cat <<EOF
${CONSTRUCTOR_PROGRAM}
${CLEANER_PROGRAM}
${SALT}
${SCHEDULED_DESTRUCTION_TIME}
EOF
	   ) | md5sum | cut --bytes 1-32 ) &&
    (
	( flock --shared 201 || exit 1 ) &&
	    if [ -d "${STRUCTURES_DIR}/${HASH}" ]
	    then
		echo "NOW=${NOW}" >> "${STRUCTURES_DIR}/${HASH}.log" &&
		    echo "${STRUCTURES_DIR}/${HASH}" &&
		    true
	    else
		(
		    ( flock 202 || exit 1 ) &&
			if [ ! -d "${STRUCTURES_DIR}/${HASH}.debug" ]
			then
			    mkdir "${STRUCTURES_DIR}/${HASH}.debug" &&
				true
			fi &&
			DEBUG_DIR=$( mktemp -d "${STRUCTURES_DIR}/${HASH}.debug/XXXXXXXX" ) &&
			mkdir "${DEBUG_DIR}/${HASH}" &&
			cd "${DEBUG_DIR}/${HASH}" &&
			BEFORE=$( date +%s ) &&
			( "${CONSTRUCTOR_PROGRAM}" > "${DEBUG_DIR}/${HASH}.out" 2> "${DEBUG_DIR}/${HASH}.err" || true ) &&
			EXIT_CODE="${?}" &&
			AFTER=$( date +%s ) &&
			( cat > "${DEBUG_DIR}/${HASH}.log" <<EOF
CONSTRUCTOR_PROGRAM= ${CONSTRUCTOR_PROGRAM}
CLEANER_PROGRAM=${CLEANER_PROGRAM}
SALT=${SALT}
SCHEDULE_DESTRUCTION_TIME=${SCHEDULED_DESTRUCTION_TIME}
ELAPSED_CONSTRUCTION_TIME=$(( ${AFTER} -  ${BEFORE} ))
EOF
			) &&
			if [ "${EXIT_CODE}" == 0 ]
			then
			    cd "${STRUCTURES_DIR}" &&
				echo "${DESTRUCTOR_PROGRAM} ${CLEANER_PROGRAM} ${HASH}" | at $( date --date "@${SCHEDULED_DESTRUCTION_TIME}" "+%H:%M %Y-%m-%d" ) > "${DEBUG_DIR}/${HASH}.at" 2>&1 &&
			        mv "${DEBUG_DIR}/${HASH}" "${DEBUG_DIR}/${HASH}.log" "${DEBUG_DIR}/${HASH}.out" "${DEBUG_DIR}/${HASH}.err" "${DEBUG_DIR}/${HASH}.at" "${STRUCTURES_DIR}" &&
				echo "${STRUCTURES_DIR}/${HASH}" &&
				true
			else
			    "${CLEANER_PROGRAM}" &&
				echo "${DEBUG_DIR}/${HASH}" &&
				true
			fi &&
			true
		) 202> "${STRUCTURES_DIR}/${HASH}.exclusive" &&
		    echo "RELEASED 202 LOCK" >> ${STRUCTURES_DIR}/at.log &&
		    true
	    fi &&
	    true
    ) 201> "${STRUCTURES_DIR}/${HASH}.shared" &&
    echo "RELEASED 201 LOCK" >> ${STRUCTURES_DIR}/at.log &&
    true
