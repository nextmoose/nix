#!/bin/sh

NOW=$( date +%s ) &&
    if [ ! -d "${STRUCTURES_DIR}" ]
    then
	mkdir "${STRUCTURES_DIR}" &&
	    true
    fi &&
    fun() {
	read GROUP_TIMESTAMP &&
	    read CLEAN_TIMESTAMP &&
	    SALT=$(${SALT_PROGRAM}) &&
	    HASH=$( echo "${CONSTRUCTOR_PROGRAM} ${SALT} ${GROUP_TIMESTAMP} ${CLEANER_PROGRAM}" | md5sum | cut 1-32  ) &&
	    echo "NOW=${NOW}" >> "${STRUCTURES_DIR}/${HASH}.log" &&
	    if [ -d "${STRUCTURES_DIR}/${HASH}" ]
	    then
		( flock --shared 203 || exit 1
		  echo "${STRUCTURES_DIR}/${HASH}" &&
		      true
		) 203> "${STRUCTURES_DIR}/${HASH}.lock" &&
		    true
	    else
		( flock 201 || exit 1 
		  mkdir "${STRUCTURES_DIR}/${HASH}" &&
		      cd "${STRUCTURES_DIR}/${HASH}" &&
		      BEFORE=$(date +%s) &&
		      ( "${CONSTRUCTOR}" > "${STRUCTURES_DIR}/${HASH}.out" 2> "${STRUCTURES_DIR}/${HASH}.err" > "${STRUCTURES_DIR}/${HASH}.time" || true ) &&
		      EXIT_CODE="${?}" &&
		      AFTER=$(date +%s) &&
		      (cat > "${STRUCTURES_DIR}/${HASH}.log" <<EOF
CONSTRUCTOR_PROGRAM=${CONSTRUCTOR}
SALT=${SALT}
TIMERS=${TIMERS}
DESTRUCTOR=${DESTRUCTOR}
GROUPER=${GROUPER}
CLEANER=${CLEANER}
EXIT_CODE=${EXIT_CODE}
CONSTRUCTION_TIME=$((${AFTER}-${BEFORE}))
EOF
		      ) &&
		      if [ "${EXIT_CODE}" == 0 ]
		      then
			  echo "cd ${STRUCTURES_DIR}/${HASH} && ${CLEAN} && cd / && rm --recursive --force ${STRUCTURES_DIR}/${HASH} ${STRUCTURES_DIR}/${HASH}.log ${STRUCTURES_DIR}/${HASH}.out ${STRUCTURES_DIR}/${HASH}.err ${STRUCTURES_DIR}/${HASH}." | at $(date --date ${CLEANER
		      else
			  mkdir "${STRUCTURES_DIR}/${HASH}.${NOW}" &&
			      mv "${STRUCTURES_DIR}/${HASH}" "${STRUCTURES_DIR}/${HASH}.log" "${STRUCTURES_DIR}/${HASH}.out" "${STRUCTURES_+DIR}/${HASH}.err" "${STRUCTURES_DIR}/${HASH}.${NOW}" &&
			      true
		      fi &&
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
