test:
	which ios-sim || brew install ios-sim
	xcodebuild test -scheme KeenClient -sdk iphonesimulator -configuration Debug RUN_UNIT_TEST_WITH_IOS_SIM=YES -arch i386