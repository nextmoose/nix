#!/bin/sh

NOW=$( date +%s ) &&
    if [ ! -d "${STRUCTURES_DIR}" ]
    then
	mkdir "${STRUCTURES_DIR}" &&
	    true
    fi &&
    if [ -z "${SALT}" ]
    then
	SALT="$( ${SALT_PROGRAM} )" &&
	    true
    fi &&
    if [ "${HAS_SCHEDULE_DESTRUCTION}" == "1" ]
    then
	SCHEDULED_DESTRUCTION_TIME=$( date --date @$(( ( ( $( date +%s ) + ${SECONDS} ) / ${SECONDS} ) * ${SECONDS} )) +%s ) &&
	    HASH=$( ( cat <<EOF
${CONSTRUCTOR_PROGRAM}
${CLEANER_PROGRAM}
${SALT}
${SCHEDULED_DESTRUCTION_TIME}
EOF
		    ) | md5sum | cut --bytes 1-32 ) &&
	    true
    else
	    HASH=$( ( cat <<EOF
${CONSTRUCTOR_PROGRAM}
${SALT}
EOF
		    ) | md5sum | cut --bytes 1-32 ) &&
		true
    fi &&
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
HAS_SCHEDULE_DESTRUCTION=${HAS_SCHEDULED_DESTRUCTION}
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
			    if [ "${HAS_SCHEDULED_DESTRUCTION}" == "1" ]
			    then
				echo "${DESTRUCTOR_PROGRAM} ${CLEANER_PROGRAM} ${STRUCTURES_DIR} ${HASH}" | /run/wrappers/bin/at $( date --date "@${SCHEDULED_DESTRUCTION_TIME}" "+%H:%M %Y-%m-%d" ) > "${STRUCTURES_DIR}/${HASH}.at" 2>&1 &&
				    true
			    fi &&
				echo "${STRUCTURES_DIR}/${HASH}" &&
				true
			else
			    if [ "${HAS_SCHEDULED_DESTRUCTION}" == "1" ]
			    then
				"${CLEANER_PROGRAM}" &&
				    true
			    fi &&
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
