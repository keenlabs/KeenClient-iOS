#!/bin/sh
set -e -o pipefail

SCRIPT_PATH=$(dirname $0)
pushd $SCRIPT_PATH
SCRIPT_FULL_PATH=$(pwd)
popd

if [[ "$XCODEBUILD_PLATFORM" == "iOS Simulator" ]]; then
	# iOS build
	XCODEBUILD_DESTINATION="platform=$XCODEBUILD_PLATFORM,OS=$XCODEBUILD_SIM_OS,name=$XCODEBUILD_DEVICE"
else
  # OS X build
	XCODEBUILD_DESTINATION="platform=$XCODEBUILD_PLATFORM"
fi

# If XCODEBUILD_WORKSPACE hasn't been set, then use the value from the Travis config
if [[ -z "$XCODEBUILD_WORKSPACE" ]] && [[ -z "$XCODEBUILD_PROJECT" ]]; then
	XCODEBUILD_WORKSPACE=$TRAVIS_XCODE_WORKSPACE
fi

if [[ -n "$XCODEBUILD_WORKSPACE" ]]; then
	XCODEBUILD_ROOT_DIR=$(dirname $XCODEBUILD_WORKSPACE)
	BUILD_TARGET_ARGUMENTS="-workspace $XCODEBUILD_WORKSPACE -scheme $TRAVIS_XCODE_SCHEME"
fi

if [[ -n "$XCODEBUILD_PROJECT" ]]; then
	XCODEBUILD_ROOT_DIR=$(dirname $XCODEBUILD_PROJECT)
	BUILD_TARGET_ARGUMENTS="-project $XCODEBUILD_PROJECT -target $XCODEBUILD_PROJECT_TARGET"
fi

case "$POD_INSTALL" in
	true)
	  pushd $XCODEBUILD_ROOT_DIR
		$SCRIPT_FULL_PATH/travis_pod_install.sh
		popd
		;;
	*)
		echo "$0: Not running pod install."
	;;
esac

case "$CARTHAGE_INSTALL" in
	true)
	  pushd $XCODEBUILD_ROOT_DIR
		$SCRIPT_FULL_PATH/travis_carthage_update.sh
		popd
		;;
	*)
		echo "$0: Not running carthage update."
	;;
esac

xcodebuild \
	$BUILD_TARGET_ARGUMENTS \
	-sdk $TRAVIS_XCODE_SDK \
	-destination "$XCODEBUILD_DESTINATION" \
	ONLY_ACTIVE_ARCH=NO clean $XCODEBUILD_ACTION | tee xcodebuild-$TRAVIS_XCODE_SCHEME.log | bundle exec xcpretty --color
