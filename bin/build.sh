#!/bin/sh
set -e -o pipefail

xcodebuild \
	-scheme KeenClient \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
  ONLY_ACTIVE_ARCH=NO \
	clean build | bundle exec xcpretty --color

xcodebuild \
	-scheme KeenSwiftClientExample \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
  ONLY_ACTIVE_ARCH=NO \
	clean build | bundle exec xcpretty --color

xcodebuild \
	-scheme KeenClientExample \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=9.2' \
  ONLY_ACTIVE_ARCH=NO \
	clean build | bundle exec xcpretty --color