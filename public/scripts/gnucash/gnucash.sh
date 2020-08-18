#!/bin/sh

cleanup() {
    umount "${MOUNT_POINT_}" &&
	umount "${MOUNT_POINT_}" &&
	true
} &&
    trap cleanup EXIT &&
    s3fs "${BUCKET}" "${MOUNT_POINT_}" &&
    encfs --paranoi "${MOUNT_POINT_}" "${MOUNT_POINT_}" &&
    cd "${MOUNT_POINT_}" &&
    gnucash &&
    true
