#!/bin/sh

echo "${PASSWORD}" | encfs --stdin --paranoia "${ROOT_DIR}" . &&
    true
