#!/bin/sh

touch config &&
    for CONFIG in "${@}"
    do
	echo "Include ${CONFIG}" >> config &&
	    true
    done &&
    chmod 0400 config &&
    chmod 0700 $(pwd) &&
    true
