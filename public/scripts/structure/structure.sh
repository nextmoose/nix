#!/bin/sh

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
#    (
#	flock --shared 202 || exit 1
	if [ -d "${STRUCTURES_DIR}/${HASH}" ]
	then
	    echo "NOW=${NOW}" >> "${STRUCTURES_DIR}/${HASH}.log" &&
		echo "${STRUCTURES_DIR}/${HASH}" &&
		true
	else
#	    (
#		flock 203 || exit 1
		if [ -d "${STRUCTURES_DIR}/${HASH}.debug" ]
		then
		    mkdir "${STRUCTURES_DIR}/${HASH}.debug" &&
			true
		fi &&
		    DEBUG_DIR=$( mktemp -d "${STRUCTURES_DIR}/${HASH}.debug/XXXXXXXX" ) &&
		    cd "${DEBUG_DIR}" &&
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
EOF
		    ) &&
		    if [ "${EXIT_CODE}" == 0 ]
		    then
			mv "${DEBUG_DIR}/${HASH}" "${DEBUG_DIR}/${HASH}.log" "${DEBUG_DIR}/${HASH}.out" "${DEBUG_DIR}/${HASH}.err" "${STRUCTURES_DIR}" &&
			    ( cat <<EOF
#(
#flock --exclusive 204 || exit 1
cd "${STRUCTURES_DIR}/${HASH}" &&
"${CLEANER_PROGRAM}"  &&
cd / &&
rm --recursive --force "${STRUCTURES_DIR}/${HASH}" "${STRUCTURES_DIR}/${HASH}.log" "${STRUCTURES_DIR}/${HASH}.out" "${STRUCTURES_DIR}/${HASH}.err" "${STRUCTURES_DIR}/${HASH}.debug"
#) 204> ${STRUCTURES_DIR}/${HASH}.lock 
EOF
			    ) | at "${SCHEDULED_DESTRUCTION_TIME}" &&
			    echo "${STRUCTURES_DIR}/${HASH}" &&
			    true
		    else
			"${CLEANER_PROGRAM}" &&
			    echo "${DEBUG_DIR}/${HASH}" &&
			    true
		    fi &&
		    true
#	    ) 203> "${STRUCTURES_DIR}/${HASH}.lock" &&
		true
	fi &&
	    true
#    ) 202> "${STRUCTURES_DIR}/${HASH}.lock" &&
    true
