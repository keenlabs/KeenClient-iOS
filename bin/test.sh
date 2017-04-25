#!/bin/sh
set -e -o pipefail

xcodebuild \
	-scheme KeenSwiftClientExample \
	-sdk iphonesimulator \
  ONLY_ACTIVE_ARCH=NO \
	clean build | bundle exec xcpretty --color

xcodebuild \
	-scheme KeenClientExample \
	-sdk iphonesimulator \
  ONLY_ACTIVE_ARCH=NO \
	clean build | bundle exec xcpretty --color

xcodebuild \
	-scheme KeenClientFramework \
	-sdk iphonesimulator \
  ONLY_ACTIVE_ARCH=NO \
	clean build | bundle exec xcpretty --color

xcodebuild \
	-scheme KeenClient \
	-sdk iphonesimulator \
	-destination 'platform=iOS Simulator,name=iPhone 6,OS=10.3' \
  ONLY_ACTIVE_ARCH=NO \
	clean test | bundle exec xcpretty --color