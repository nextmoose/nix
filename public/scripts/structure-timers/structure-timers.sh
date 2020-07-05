#!/bin/sh

ALPHA=$(date --date @$((${@})) "+%Y-%m-%d %H:%M") &&
    BETA=$(date --date @$((${@}+60*5)) +%s) &&
    GAMMA=$(date --date @$((${@}+60)) "+%Y-%m-%d %H:%M") &&
    DELTA=$(date --date @$((${@}+60*6)) +%s) &&
    date --date "${ALPHA}" +%s &&
    date --date @${BETA} +%s &&
    date --date "${GAMMA}" +%s &&
    date --date @${DELTA} +%s &&
    true
