#!/bin/sh
set -e -o pipefail

if [[ "$XCODEBUILD_PLATFORM" == "iOS Simulator" ]]; then
	# iOS build
	XCODEBUILD_DESTINATION="platform=$XCODEBUILD_PLATFORM,OS=$XCODEBUILD_SIM_OS,name=$XCODEBUILD_DEVICE"
else
  # OS X build
	XCODEBUILD_DESTINATION="platform=$XCODEBUILD_PLATFORM"
fi

xcodebuild \
	-workspace $TRAVIS_XCODE_WORKSPACE \
	-scheme $TRAVIS_XCODE_SCHEME \
	-sdk $TRAVIS_XCODE_SDK \
	-destination "$XCODEBUILD_DESTINATION" \
	ONLY_ACTIVE_ARCH=NO clean $XCODEBUILD_ACTION | bundle exec xcpretty --color
