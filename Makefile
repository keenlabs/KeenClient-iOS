test:
	which ios-sim || brew install ios-sim
	xcodebuild -target KeenClientTests -sdk iphonesimulator -configuration Debug RUN_UNIT_TEST_WITH_IOS_SIM=YES TEST_AFTER_BUILD=YES