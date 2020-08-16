#!/bin/sh

(cat <<EOF
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCES_KEY}
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
EOF
) &&
    if [ -z "$( aws s3 ls "s3://${BUCKET}" )" ]
    then
	aws s3 cp "s3://${BUCKET}" . --recursive &&
	    true
    fi &&
    true
