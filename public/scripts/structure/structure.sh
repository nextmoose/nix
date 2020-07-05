#!/bin/sh

NOW=$( date +%s ) &&
    fun() {
	read GROUPER &&
	    read CLEANER &&
	    (cat > test.txt <<EOF
GROUPER=${GROUPER}
CLEANER=${CLEANER}
EOF
	    ) &&
	    true
    } &&
    "${TIMERS}" "${NOW}" | while fun
    do
	echo fun &&
	    true
    done &&
    true
