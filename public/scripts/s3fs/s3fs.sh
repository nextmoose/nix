#!/bin/sh

if [ -z "$( aws s3api list-buckets --output text --query "Buckets[?Name=='${BUCKET}'].Name" )" ]
then
    aws s3api create-bucket --acl private --bucket "${BUCKET}" &&
	true
fi &&
    s3fs "${BUCKET}" . -o "acl=private" &&
    true
