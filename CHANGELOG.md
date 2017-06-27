# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).


## [3.7.0] - 2017-06-26
### Added
- Support for querying saved and cached queries
- Support for querying datasets
- Support for HTTP proxies
- Support for custom API URL base authority

## [3.6.2] - 2017-06-08
### Fixed
- Fixed issue where calling `uploadWithFinishedBlock:` quickly in succession could cause duplicate event uploads.

## [3.6.1] - 2017-05-12
### Fixed
- Fixed missing headers from framework build

## [3.6.0] - 2017-04-05
### Added
- Extensibility hooks for custom logging implementations.

### Changed
- Updated Travis CI image to Xcode 8.2
- Enabled bundler gem caching for faster CI builds
- Added example apps to CI build

### Fixed
- Fixed bug where KIODBStore would close and reopen DB when performing any query, which could contribute to experiencing issue #183 more often.
- Fixed a similar issue where KIODBStore would close and reopen the DB when attempting to get a query that wasn't in the DB, also leading to more observations of #183.
- Fixed unit test setup issues leading to non-deterministic test failures.
- Fixed unit test issues where async tests weren't waiting for completion of async operations.
- Fixed issue #156, which could lead to duplicate event uploads.
- Fixed Travis CI issue where test.sh wouldn't correctly report a build failure.
- Fixed build break in example Obj-C app

## [3.5.7] - 2017-03-03
### Changed
- Added SDK platform and version info header to requests.
- Updated Swift example project to Swift 3 syntax. #175
- Added method to disable automatically requesting CoreLocation authentication.

### Fixed
- Fixed handling of database corruption under certain circumstances.

## [3.5.6] - 2016-08-05
### Fixed
- Fixed app crashing when NSDate conversion to ISO8601 failed. Removed dependency on SQLite to convert date in favor of NSDateFormatter, which is thread-safe on iOS >=7 and OS X >=10.9. #165

## [3.5.5] - 2016-06-28
### Fixed
- Fixed handling of SQLite errors on `getEventsWithMaxAttempts`, `closeDB`, and `prepareAllSQLiteStatements` methods.

## [3.5.4] - 2016-06-13
### Fixed
- Fixed `uploadWithFinishedBlock` method that was not calling the user passed block if the upload failed. #155
- Fixed Xcode `KeenClient-Prefix.pch.pch: No such file or directory` warnings when compiling app.

### Changed
- Disabled printing Reachability flags to console by default. #153
- Increased iOS Deployment Target to 7.0.

## [3.5.3] - 2016-03-28
### Added
- Added test coverage integration with Coveralls by using the Slather gem. Added configuration file .slather.yml for use with Slather.
- Added Gemfile with `Slather` and `xcpretty` gems for use with Travis CI.
- Added shell script to run tests in `bin/test.sh`. Outputs each individual test and if it succeeded or failed.

### Changed
- Changed .travis.yml file to use the shell script `bin/test.sh` instead of Makefile.

### Removed
- Removed Makefile in favor of `/bin/test.sh`.
- Removed unused docs folder and `generate_docs.sh` script.

### Fixed
- Fixed bug where an app would crash in case the database was corrupted, by checking for the `SQLITE_CORRUPT` flag when database is opened, and deleting it if true.  #121

## [3.5.2] - 2016-02-04
### Added
- Added support for Carthage. Added a Dynamic Framework scheme, and changed its setting to "Shared" so Carthage can use it.

## [3.5.1] - 2016-01-27
### Fixed
- Updated Swift example project to conform with new Swift 2 syntax. Also added the timeframe parameter to all queries in example projects to conform with Keen query requirements. #132
- Updated project properties using Xcode's recommended settings: "Build Settings" to Standard architectures, "Product Bundle Identifier", and "Enable Testability".
- Updated project settings for Objective-C and Swift sample apps.
- Updated OCMock to v3.2.1.
- Fixed KeenClientTests warnings.
- Fixed Reachability potential memory leak error, updated it to latest version found on [Apple Developer website](https://developer.apple.com/library/ios/samplecode/Reachability/Introduction/Intro.html). #133
- Fixed a few errors in the README.md file.
- Fixed `sendSynchronousRequest:returningResponse:error:` deprecated warnings, updated methods to use NSURLSession `dataTaskWithRequest:completionHandler`. #136

### Changed
- Changed the KeenClientExample project deployment target to 6.0, so it can be deployed to a device when bitcode is enabled.
- Removed KeenClient-Device and KeenClient-Simulator targets.
- Changed the KeenClient-Aggregate "Run Script" phase to use `xcodebuild`, and build the KeenClient target for both simulator and device with bitcode support. #140

## [3.5.0] - 2015-12-29
### Added
- Added a query attempts limit functionality, to help users avoid running into rate limit issues. This only works for calls to the Keen Query API that return a 4XX response. Two variables were added to the `KeenClient` class, `maxQueryUploadAttempts` and `queryTTL`. The first one is a threshold for how many times a query should be attempted. The second is a threshold in seconds for how long the failed queries attempts should stay in the database. #105

### Changed
- Changed `maxAttempts` variable to `maxEventUploadAttempts`.

### Fixed
- Fixed error with `MultiAnalysisQueries` method on running an invalid comparison when trying to insure all `KIOQuery` had the same `eventCollection` properties, and also moved all properties (filters, timeframe, timezone, group_by, interval) from the `KIOQuery` objects to the final multi-analysis dictionary. #124 #125 #128

## [3.4.3] - 2015-08-10
### Fixed
- Fixed sqlite EXC_BAD_ACCESS crash that was happening because of `NSString UTF8String` calls inside `KIOEventStore` dispatch_sync blocks, followed by a call to `resetSQLiteStatement`. #114

## [3.4.2] - 2015-08-07
### Fixed
- Fixed sqlite migration error that was starting a transaction and not finishing it,  keeping events from being saved. #113

## [3.4.1] - 2015-07-22
### Fixed
- Fixed uploading events with multiple instances of KeenClient. All instances of `sharedClientWithProjectId` must now use `sharedClientWithProjectID` instead.

## [3.4.0] - 2015-07-08
### Added
- Added querying capability to SDK.

## [3.3.1] - 2015-06-12
### Fixed
- Fixed warning about deprecated SenTestingKit, converted it to XCTest.

### Changed
- Added the prefix KIO to Reachability files and all its methods to avoid duplicate erros with other projects or Pods. #97
- Moved sqlite files to a subspec inside the KeenClient.podspec file, and added compiler flags to them to suppress warnings in other projects.

## [3.3.0] - 2015-05-27
### Added
- Added Network Reachability check before uploading events and SystemConfiguration framework.
- Added SQLite database versioning and migration capabilities.
- Added max number of upload retries to events. The default value is 3 attempts, and it can be changed by setting the `client.maxAttempts` variable.
- Added KeenSwiftClientExample project and updated README to include Swift code examples.

### Changed
- Refactored KIOEventStore to reopen connection to database in case it's closed by a SQLite failure.
- Updated code to accept all HTTP 2xx status codes.

### Fixed
- Fixed uploading empty data when requests dictionary was empty. PR #75
- Fixed first-time app startup Cocoa error 260 bug where keenSubDirectories does not exist yet.
- Fixed Xcode warnings.

## [3.2.20] - 2014-11-07
- Skipped 3.2.19 due to CocoaPods versioning issue.

### Fixed
- Fixed semaphore_wait_trap issue caused by recursive calls of dispatch_sync.

## [3.2.18] - 2014-10-28
### Fixed
- Fixed erroneous removal of disableGeoLocation method call from KeenClient.h.

## [3.2.17] - 2014-10-27
### Fixed
- Fixed bug created in CocoaPods by 3.2.16.

## [3.2.16] - 2014-10-27
### Added
- Added support for `requestWhenInUseAuthorization` and `requestAlwaysAuthorization` in iOS 8.

## [3.2.15] - 2014-09-17
### Added
- Added KeenClient-Cocoa build target/universal binary to support Mac OS X
- Added convertNSDateToISO8601 to dispatch queue

### Changed
- Updated GitHub documentation to match documentation found at [keen.io](http://keen.io)
- Refactored semaphores to use dispatch_sync and cleaned up instances of dispatch_retain

## [3.2.14] - 2014-08-01
### Fixed
- Fixed analyzer warnings.
- Fixed methods returning NSErrors as double pointers.

### Changed
- Enabled ARC in Simulator and Device targets.

## [3.2.13] - 2014-07-22
### Changed
- Updated podspec to include c source for sqlite3.

## [3.2.12] - 2014-07-21
- Skipped 3.2.11 versioning in favor of 3.2.12 to workaround Cocoapods versioning issue.

### Added
- Added sdkVersion class method.
- Added call to resetPendingEvents in getEvents.

### Fixed
- Fixed KEEN\_LOGGING\_ macro.
- Fixed instance client issues created by KIOEventStore implementation.

### Changed
- Converted KeenClient to use ARC.
- Renamed all SQLite files with keen\_io\_ prefix.
- Moved keen\_io\_sqlite3.h import to KIOEventStore.m.
- Replaced usage of NSDateFormatter with SQLite based date conversion (thread safe).

## [3.2.10] - 2014-06-20
### Added
- Added queuing to KIOEventStore to ensure SQLite calls are serialized.
- Added sqlite-amalgamation library to eliminate dependency on libsqlite3.dylib.
- Added SDK version string to logging.

### Fixed
- Fixed array allocation/deallocation bug in prepareJSONData.

## [3.2.9] - 2014-06-11
### Changed
- Replaced use of filesystem's cache directory with SQLite via KIOEventStore.

## [3.2.8] - 2014-06-05
### Fixed
- Upload with finished block consistency fix.

## [3.2.7] - 2014-04-26
### Added
- Support sending addons in events.

## [3.2.6] - 2014-03-22
### Fixed
- Bugfix to always invoke callback on upload, even if there are no events to upload.

## [3.2.5] - 2014-02-19
### Changed
- Remove ISO8601DateFormatter dependency.
- Use Grand Central Dispatch to not spawn one thread per upload invocation.

### Fixed
- Don't throw exceptions and crash the app when the local cache directory is unavailable.

## [3.2.4] - 2013-12-05
### Changed
- Get semantic versioning cleaned up for cocoapods (somehow got confused between 3.2.2 and 3.2.3).

## [3.2.2] - 2013-04-23
### Added
- Support for iOS 7 and ARM64.

### Changed
- Removed JSONKit dependency in favor of NSJONSerialization.

## [3.2.1] - 2013-04-23
### Added
- Added support for read and write scoped keys.
- Added support for travis.

### Changed
- Changed project token -> project ID.

[unreleased]: https://github.com/keenlabs/KeenClient-iOS/compare/3.5.6...HEAD
[3.5.6]: https://github.com/keenlabs/KeenClient-iOS/compare/3.5.5...3.5.6
[3.5.5]: https://github.com/keenlabs/KeenClient-iOS/compare/3.5.4...3.5.5
[3.5.4]: https://github.com/keenlabs/KeenClient-iOS/compare/3.5.3...3.5.4
[3.5.3]: https://github.com/keenlabs/KeenClient-iOS/compare/3.5.2...3.5.3
[3.5.2]: https://github.com/keenlabs/KeenClient-iOS/compare/3.5.1...3.5.2
[3.5.1]: https://github.com/keenlabs/KeenClient-iOS/compare/3.5.0...3.5.1
[3.5.0]: https://github.com/keenlabs/KeenClient-iOS/compare/3.4.3...3.5.0
[3.4.3]: https://github.com/keenlabs/KeenClient-iOS/compare/3.4.2...3.4.3
[3.4.2]: https://github.com/keenlabs/KeenClient-iOS/compare/3.4.1...3.4.2
[3.4.1]: https://github.com/keenlabs/KeenClient-iOS/compare/3.4.0...3.4.1
[3.4.0]: https://github.com/keenlabs/KeenClient-iOS/compare/3.3.1...3.4.0
[3.3.1]: https://github.com/keenlabs/KeenClient-iOS/compare/3.3.0...3.3.1
[3.3.0]: https://github.com/keenlabs/KeenClient-iOS/compare/3.2.20...3.3.0
[3.2.20]: https://github.com/keenlabs/KeenClient-iOS/compare/3.2.18...3.2.20
[3.2.18]: https://github.com/keenlabs/KeenClient-iOS/compare/3.2.17...3.2.18
[3.2.17]: https://github.com/keenlabs/KeenClient-iOS/compare/3.2.16...3.2.17
[3.2.16]: https://github.com/keenlabs/KeenClient-iOS/compare/3.2.15...3.2.16
[3.2.15]: https://github.com/keenlabs/KeenClient-iOS/compare/3.2.14...3.2.15
[3.2.14]: https://github.com/keenlabs/KeenClient-iOS/compare/3.2.13...3.2.14
[3.2.13]: https://github.com/keenlabs/KeenClient-iOS/compare/3.2.12...3.2.13
[3.2.12]: https://github.com/keenlabs/KeenClient-iOS/compare/3.2.10...3.2.12
[3.2.10]: https://github.com/keenlabs/KeenClient-iOS/compare/3.2.9...3.2.10
[3.2.9]: https://github.com/keenlabs/KeenClient-iOS/compare/3.2.8...3.2.9
[3.2.8]: https://github.com/keenlabs/KeenClient-iOS/compare/v3.2.7...3.2.8
[3.2.7]: https://github.com/keenlabs/KeenClient-iOS/compare/v3.2.6...v3.2.7
[3.2.6]: https://github.com/keenlabs/KeenClient-iOS/compare/v3.2.5...v3.2.6
[3.2.5]: https://github.com/keenlabs/KeenClient-iOS/compare/v3.2.4...v3.2.5
[3.2.4]: https://github.com/keenlabs/KeenClient-iOS/compare/v3.2.2...v3.2.4
[3.2.2]: https://github.com/keenlabs/KeenClient-iOS/compare/v3.2.1...v3.2.2
[3.2.1]: https://github.com/keenlabs/KeenClient-iOS/compare/v3.2.0...v3.2.1
