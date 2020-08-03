#!/bin/sh

git init &&
    ln --symbolic "${POST_COMMIT_PROGRAM}" .git/hooks/post-commit &&
    git config core.sshCommand "${SSH_PROGRAM}" &&
    git config user.name "${COMMITTER_NAME}" &&
    git config user.email "${COMMITTER_EMAIL}" &&
    git remote add upstream "${UPSTREAM_URL}" &&
    git remote set-url --push upstream no_push &&
    git remote add personal "${PERSONAL_URL}" &&
    git remote add report "${REPORT_URL}" &&
    git fetch personal "${PERSONAL_BRANCH}" &&
    git checkout "${PERSONAL_BRANCH}" &&
    true
