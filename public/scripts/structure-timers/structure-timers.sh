#!/bin/sh

date --date "@${@}" "+%Y%m%d%H%M" &&
    date --date "@$((${@}+(60*5)))" +%s &&
    date --date "@$((${@}+60))" "+%Y%m%d%H%M" &&
    date --date "@$((${@}+60+(60*5)))" +%s &&
    true
