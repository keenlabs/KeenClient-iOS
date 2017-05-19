#!/bin/sh
set -e -o pipefail

if [[ "$XCODEBUILD_PLATFORM" == "iOS Simulator" ]]; then
	# iOS build
	XCODEBUILD_DESTINATION="platform=$XCODEBUILD_PLATFORM,OS=$XCODEBUILD_SIM_OS,name=$XCODEBUILD_DEVICE"
else
  # OS X build
	XCODEBUILD_DESTINATION="platform=$XCODEBUILD_PLATFORM"
fi

# If XCODEBUILD_WORKSPACE hasn't been set, then use the value from the Travis config
if [[ -z "$XCODEBUILD_WORKSPACE" ]]; then
	XCODEBUILD_WORKSPACE=$TRAVIS_XCODE_WORKSPACE
fi

case "$POD_INSTALL" in
	true)
	  pushd $(dirname $XCODEBUILD_WORKSPACE)
		pod install
		popd
		;;
	*)
		echo "$0: Not running pod install."
	;;
esac

xcodebuild \
	-workspace $XCODEBUILD_WORKSPACE \
	-scheme $TRAVIS_XCODE_SCHEME \
	-sdk $TRAVIS_XCODE_SDK \
	-destination "$XCODEBUILD_DESTINATION" \
	ONLY_ACTIVE_ARCH=NO clean $XCODEBUILD_ACTION | bundle exec xcpretty --color
