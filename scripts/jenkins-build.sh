#!/bin/bash

set -e
set -o pipefail

step () {
	echo "==== $@"
}

msg () {
	echo "== $@"
}

step "Initializing build environment"
make setup

export GIT_DEPLOY_DIR=dist
export GIT_DEPLOY_BRANCH=gh-pages

CURRENT_BRANCH=${GIT_BRANCH##*/}

if [ $CURRENT_BRANCH = "master" ]; then
    export GIT_DEPLOY_REPO=origin
    VERSION=$(python ./.autobuild-utilities/versioner.py --verbose)
else
    msg "Can't deploy anything but master."
    exit 1
fi

step "Building ${VERSION} on ${CURRENT_BRANCH} at ${GIT_COMMIT}"

msg "building docs"
make all

msg "deploying"
bash scripts/deploy.sh -v
