#!/bin/sh

KEY_ID="$( jq -r ".id" ${CREATE_DIR}/response.json )" &&
    curl \
	--header "Authorization: token ${PERSONAL_ACCESS_TOKEN}" \
	"https://api.github.com/user/${KEY_ID}" &&
    rm --recursive --force "${CREATE_DIR}" &&
    true
