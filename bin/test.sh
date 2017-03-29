#!/bin/sh
set -e -o pipefail

xcodebuild \
	-scheme KeenClient \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
	-enableCodeCoverage YES \
  ONLY_ACTIVE_ARCH=NO \
	clean test | xcpretty --color

xcodebuild \
	-scheme KeenSwiftClientExample \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
  ONLY_ACTIVE_ARCH=NO \
	clean build | xcpretty --color

xcodebuild \
	-scheme KeenClientExample \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
  ONLY_ACTIVE_ARCH=NO \
	clean build | xcpretty --color