#!/bin/sh

echo "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" > password-file.asc &&
    chmod 0400 password-file.asc &&
    true
