#!/bin/sh

date --date $(date --date $((${@})) +%Y-%m-%d-%H:%M) +%s &&
    date --date $(date --date @$((${@}+60*5)) +%s) +%s &&
    date --date $(date --date $((${@}+60)) +%Y-%m-%d-%H:%M) +%s &&
    date --date $(date --date @$((${@}+60*6)) +%s) +%s &&
    true
