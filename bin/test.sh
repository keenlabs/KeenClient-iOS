#!/bin/sh
set -e -o pipefail

xcodebuild \
	-scheme KeenSwiftClientExample \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
  ONLY_ACTIVE_ARCH=NO \
	clean build | tee xcodebuild-KeenSwiftClientExample.log | bundle exec xcpretty --color

xcodebuild \
	-scheme KeenClientExample \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
  ONLY_ACTIVE_ARCH=NO \
	clean build | tee xcodebuild-KeenClientExample.log | bundle exec xcpretty --color

xcodebuild \
	-scheme KeenClientFramework \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
  ONLY_ACTIVE_ARCH=NO \
	clean build | tee xcodebuild-KeenClientFramework.log | bundle exec xcpretty --color

xcodebuild \
	-scheme KeenClient \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
  ONLY_ACTIVE_ARCH=NO \
	clean test | tee xcodebuild-KeenClient.log | bundle exec xcpretty --color