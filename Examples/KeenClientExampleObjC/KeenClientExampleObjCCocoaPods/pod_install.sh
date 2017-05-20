#!/bin/bash

# This script generates a Podfile that specifies the current git branch
# in order to install that version of the pod. Otherwise we'd always get
# master and CI validation wouldn't be useful for other branches
SCRIPT_DIR=$(dirname $0)
cd $SCRIPT_DIR
SCRIPT_DIR_FULL_PATH=$(pwd)

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "target 'KeenClientExampleObjCCocoaPods' do" > Podfile
echo "    pod 'KeenClient', :path => '../../..', :branch => '$CURRENT_BRANCH'" >> Podfile
echo "end" >> Podfile

pod install