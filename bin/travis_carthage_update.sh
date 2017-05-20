#!/bin/bash

# Carthage doesn't work with local relative paths, so this script generates
# a Cartfile with a full path to the root of this git repository, and then
# runs carthage update
SCRIPT_PATH=$(dirname $0)
pushd $SCRIPT_PATH
SCRIPT_FULL_PATH=$(pwd)
popd

CARTHAGE_GIT_ROOT=$SCRIPT_FULL_PATH/../../KeenClient-iOS

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "git \"file://$CARTHAGE_GIT_ROOT\" \"$CURRENT_BRANCH\"" > Cartfile

carthage update