#!/bin/sh

if [ -z "$( aws s3api list-buckets --output text --query "Buckets[?Name=='${BUCKET}'].Name" )" ]
then
    aws s3api create-bucket --acl private --bucket "${BUCKET}" &&
	true
else
    aws s3 cp "s3://${BUCKET}" . --recursive --sse &&
	true
fi &&
    true
