#!/bin/sh

if [ -z "$( aws s3 ls "s3://${BUCKET}" )" ]
then
    aws s3 cp "s3://${BUCKET}" . --recursive &&
	true
fi &&
    true
