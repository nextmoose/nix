#!/bin/sh

(
    (
	flock 301 || exit true
    ) &&
	NOW=$( date +%s ) &&
	if [ ! -d "${STRUCTURES_DIR}" ]
	then
	    mkdir "${STRUCTURES_DIR}" &&
		true
	fi &&
	SALT=$( ${SALT_PROGRAM} ) &&
	SCHEDULED_DESTRUCTION_TIME=$( date --date @$((((${NOW}+${SECONDS})/${SECONDS})*${SECONDS})) "+%H:%M %Y-%m-%d" ) &&
	HASH=$( ( cat <<EOF
${CONSTRUCTOR_PROGRAM}
${CLEANER_PROGRAM}
${SALT}
${SCHEDULED_DESTRUCTION_TIME}
EOF
		) | md5sum | cut --bytes 1-32 ) &&
	(
	    (
		flock --shared 303 || exit 1
	    ) &&
	    if [ -d "${STRUCTURES_DIR}/${HASH}" ]
	    then
		echo "NOW=${NOW}" >> "${STRUCTURES_DIR}/${HASH}.log" &&
		    echo "${STRUCTURES_DIR}/${HASH}" &&
		    true
	    else
		(
		    ( flock --shared 304 || exit 1 ) &&
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
NOW=${NOW}
CONSTRUCTOR_PROGRAM=${CONSTRUCTOR_PROGRAM}
CLEANER_PROGRAM=${CLEANER_PROGRAM}
SALT=${SALT}
SCHEDULED_DESTRUCTION_TIME=${SCHEDULED_DESTRUCTION_TIME}
EXIT_CODE=${EXIT_CODE}
CONSTRUCTION_DURATION=$((${AFTER}-${BEFORE}))
HASH=${HASH}
EOF
			) &&
			if [ "${EXIT_CODE}" == 0 ]
			then
			    mv "${DEBUG_DIR}/${HASH}" "${DEBUG_DIR}/${HASH}.log" "${DEBUG_DIR}/${HASH}.out" "${DEBUG_DIR}/${HASH}.err" "${STRUCTURES_DIR}" &&
				rm --recursive --force "${DEBUG_DIR}" &&
				( cat <<EOF
(
    ( flock --shared 301 || exit 1 ) &&
        (
            ( flock --shared 303 || exit 1 ) &&
                (
                    ( flock 302 || exit 1 ) &&
                        cd "${STRUCTURES_DIR}/${HASH}" &&
                        "${CLEANER_PROGRAM}" > "${STRUCTURES_DIR}/${HASH}.clean" 2>&1 &&
                        rm --recursive --force "${STRUCTURES_DIR}/${HASH}" "${STRUCTURES_DIR}/${HASH}.log" "${STRUCTURES_DIR}/${HASH}.out" "${STRUCTURES_DIR}/${HASH}.err" "${STRUCTURES_DIR}/${HASH}.at" "${STRUCTURES_DIR}/${HASH}.debug" "${STRUCTURES_DIR}/${HASH}.clean" &&
                        true
                ) 302> "${STRUCTURES_DIR}/${HASH}.exlusive" &&
		rm "${STRUCTURES_DIR}/${HASH}.exclusive" &&
                true
        ) 303> "${STRUCTURES_DIR}/${HASH}.shared" &&
	rm "${STRUCTURES_DIR}/${HASH}.shared" &&
        true
) 301> "${STRUCTURES_DIR}.shared" &&
    true
EOF
				) | /run/wrappers/bin/at "${SCHEDULED_DESTRUCTION_TIME}" > "${STRUCTURES_DIR}/${HASH}.at" 2>&1 && ## KLUDGE
				echo "${STRUCTURES_DIR}/${HASH}" &&
				true
			else
			    "${CLEANER_PROGRAM}" &&
				echo "${DEBUG_DIR}/${HASH}" &&
				true
			fi &&
			true
		) 304> "${STRUCTURES_DIR}/${HASH}.exclusive" &&
		    true
	    fi &&
		true
	) 303> "${STRUCTURES_DIR}/${HASH}.shared" &&
	true
) 301> "${STRUCTURES_DIR}.shared" &&
    true
