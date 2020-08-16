#!/bin/sh

export HOME=$( pwd ) &&
    (cat <<EOF
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_DEFAULT_REGION}

EOF
    ) | aws configure &&
    true
