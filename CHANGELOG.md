# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).


## [Unreleased][unreleased]
### Added
- Added a query attempts limit functionality, to help users avoid running into rate limit issues. This only works for calls to the Keen Query API that return a 4XX response. Two variables were added to the `KeenClient` class, `maxQueryUploadAttempts` and `querySecondsLifespan`. The first one is a threshold for how many times a query should be attempted. The second is a threshold in seconds for how long the failed queries attempts should stay in the database. #105

### Changed
- Changed `maxAttempts` variable to `maxEventUploadAttempts`.

### Fixed
- Fixed error with `MultiAnalysisQueries` method on running an invalid comparison when trying to insure all `KIOQuery` had the same `eventCollection` properties, and also moved all properties (filters, timeframe, timezone, group_by, interval) from the `KIOQuery` objects to the final multi-analysis dictionary. #124 #125

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

[unreleased]: https://github.com/keenlabs/KeenClient-iOS/compare/3.4.3...HEAD
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
