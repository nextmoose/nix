#!/bin/sh

aws s3 cp "${STRUCTURE_DIR}" "s3://${BUCKET}" --recursive --sse &&
    rm --recursive --force "${STRUCTURE_DIR}" &&
    true
