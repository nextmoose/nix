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
			mkdir "${STRUCTURES_DIR}/${HASH}" &&
			cd "${STRUCTURES_DIR}/${HASH}" &&
			BEFORE=$( date +%s ) &&
			( "${CONSTRUCTOR_PROGRAM}" > "${STRUCTURES_DIR}/${HASH}.out" 2> "${STRUCTURES_DIR}/${HASH}.err" || true ) &&
			EXIT_CODE="${?}" &&
			AFTER=$( date +%s ) &&
			( cat > "${STRUCTURES_DIR}/${HASH}.log" <<EOF
CONSTRUCTOR_PROGRAM=${CONSTRUCTOR_PROGRAM}
CLEANER_PROGRAM=${CLEANER_PROGRAM}
SALT=${SALT}
SCHEDULE_DESTRUCTION_TIME=${SCHEDULED_DESTRUCTION_TIME}
ELAPSED_CONSTRUCTION_TIME=$(( ${AFTER} -  ${BEFORE} ))
EXIT_CODE=${EXIT_CODE}
EOF
			) &&
			if [ "${EXIT_CODE}" == 0 ]
			then
			    # KLUDGE -- WTF AT
			    echo "${DESTRUCTOR_PROGRAM} ${CLEANER_PROGRAM} ${STRUCTURES_DIR} ${HASH}" | /run/wrappers/bin/at $( date --date "@${SCHEDULED_DESTRUCTION_TIME}" "+%H:%M %Y-%m-%d" ) > "${STRUCTURES_DIR}/${HASH}.at" 2>&1 &&
				echo "${STRUCTURES_DIR}/${HASH}" &&
				true
			else
			    "${CLEANER_PROGRAM}" &&
				if [ ! -d "${STRUCTURES_DIR}/${HASH}.debug" ]
				then
				    mkdir "${STRUCTURES_DIR}/${HASH}.debug" &&
					true
				fi &&
				DEBUG_DIR=$( mktemp -d "${STRUCTURES_DIR}/${HASH}.debug/XXXXXXXX" ) &&
				cd "${DEBUG_DIR}" &&
			        mv "${STRUCTURES_DIR}/${HASH}" "${STRUCTURES_DIR}/${HASH}.log" "${STRUCTURES_DIR}/${HASH}.out" "${STRUCTURES_DIR}/${HASH}.err" "${STRUCTURES_DIR}/${HASH}.at" "${DEBUG_DIR}" &&
				echo "${DEBUG_DIR}/${HASH}" &&
				exit "${EXIT_CODE}" &&
				true
			fi &&
			true
		) 202> "${STRUCTURES_DIR}/${HASH}.exclusive" &&
		    true
	    fi &&
	    true
    ) 201> "${STRUCTURES_DIR}/${HASH}.shared" &&
    true
