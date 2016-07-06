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
# Smite any previous Quark & NVM installations
rm -rf .autobuild-quark .autobuild-nvm

# Setup node environment
msg "nvm..."

cp /dev/null .nvm_fake_profile
NVM_DIR="$(pwd)/.autobuild-nvm"

# Yes, really, the NVM_DIR setting in the 'env' command below does make sense.
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | \
	env NVM_DIR="$NVM_DIR" PROFILE="$(pwd)/.nvm_fake_profile" bash

[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

nvm install 4.2.2 && nvm alias default 4.2.2

# Do local setup
make QUARKINSTALLARGS="-qqq -t $(pwd)/.autobuild-quark" QUARKBRANCH="develop" setup
. $(pwd)/.autobuild-quark/config.sh

export GIT_DEPLOY_DIR=dist
export GIT_DEPLOY_BRANCH=gh-pages

CURRENT_BRANCH=${GIT_BRANCH##*/}

if [ $CURRENT_BRANCH = "master" ]; then
    export GIT_DEPLOY_REPO=origin
else
    msg "Can't deploy anything but master."
    exit 1
fi

step "Building ${CURRENT_BRANCH} at ${GIT_COMMIT}"

msg "building docs"
make all

msg "deploying"
bash scripts/deploy.sh -v
