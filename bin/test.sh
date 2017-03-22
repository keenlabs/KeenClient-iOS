#!/bin/sh
set -e -o pipefail

xcodebuild \
	-scheme KeenClient \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
	-enableCodeCoverage YES \
  ONLY_ACTIVE_ARCH=NO \
	test | bundle exec xcpretty --color