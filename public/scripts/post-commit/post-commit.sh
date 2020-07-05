#!/bin/sh

while ! git push "${REMOTE}" HEAD
do
    sleep 1s &&
	true
done &&
    true
