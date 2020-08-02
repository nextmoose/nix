#!/bin/sh

curl \
    --header "Authorization: token ${PERSONAL_ACCESS_TOKEN}" \
    --data "{\"title\": \"${TITLE}\", \"key\": \"${SSH_PUBLIC_KEY}\"}" \
    https://api.github.com/user/keys > key.json
