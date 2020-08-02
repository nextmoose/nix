#!/bin/sh

curl \
    --header "Authorization: token ${PERSONAL_ACCESS_TOKEN}" \
    --data "{\"title\": \"${TITLE}\", \"key\": \"${PUBLIC_SSH_KEY}\"}" \
    https://api.github.com/user/keys > key.json
