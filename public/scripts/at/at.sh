#!/bin/sh

# KLUDGE

tee | at ${@} &&
    true
