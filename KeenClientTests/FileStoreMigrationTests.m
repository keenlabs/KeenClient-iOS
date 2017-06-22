//
//  FileStoreMigrationTests.m
//  KeenClient
//
//  Created by Brian Baumhover on 5/9/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenClient.h"

#import "KeenClientTestable.h"
#import "KeenTestConstants.h"
#import "KeenTestUtils.h"
#import "KIOFileStore.h"

#import "FileStoreMigrationTests.h"

@implementation FileStoreMigrationTests

- (void)testMigrateFSEvents {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    // make sure the directory we want to write the file to exists
    NSString *dirPath = [KeenTestUtils eventDirectoryForCollection:@"foo"];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    [manager createDirectoryAtPath:dirPath withIntermediateDirectories:true attributes:nil error:&error];
    XCTAssertNil(error, @"created directory for events");

    // Write out a couple of events that we can import later!
    NSDictionary *event1 = [NSDictionary dictionaryWithObject:@"apple" forKey:@"a"];
    NSDictionary *event2 = [NSDictionary dictionaryWithObject:@"orange" forKey:@"b"];

    NSData *json1 = [NSJSONSerialization dataWithJSONObject:event1 options:0 error:&error];
    NSData *json2 = [NSJSONSerialization dataWithJSONObject:event2 options:0 error:&error];

    NSString *fileName1 = [KeenTestUtils pathForEventInCollection:@"foo" WithTimestamp:[NSDate date]];
    NSString *fileName2 = [KeenTestUtils pathForEventInCollection:@"foo" WithTimestamp:[NSDate date]];

    [KeenTestUtils writeNSData:json1 toFile:fileName1];
    [KeenTestUtils writeNSData:json2 toFile:fileName2];

    [KIOFileStore importFileDataWithProjectID:kDefaultProjectID];
    // Now we're gonna add an event and verify the events we just wrote to the fs
    // are added to the database and the files are cleaned up.
    error = nil;
    NSDictionary *event3 = @{ @"nested": @{@"keen": @"whatever"} };
    [client addEvent:event3 toEventCollection:@"foo" error:nil];

    XCTAssertEqual(3,
                   [KIODBStore.sharedInstance getTotalEventCountWithProjectID:client.config.projectID],
                   @"There should be 3 events after an import.");
    XCTAssertFalse([manager fileExistsAtPath:[KeenTestUtils keenDirectory] isDirectory:true],
                   @"The Keen directory should be gone.");
}

- (void)testMigrateFSEventsInstanceClient {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    // make sure the directory we want to write the file to exists
    NSString *dirPath = [KeenTestUtils eventDirectoryForCollection:@"foo"];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    [manager createDirectoryAtPath:dirPath withIntermediateDirectories:true attributes:nil error:&error];
    XCTAssertNil(error, @"created directory for events");

    // Write out a couple of events that we can import later!
    NSDictionary *event1 = [NSDictionary dictionaryWithObject:@"apple" forKey:@"a"];
    NSDictionary *event2 = [NSDictionary dictionaryWithObject:@"orange" forKey:@"b"];

    NSData *json1 = [NSJSONSerialization dataWithJSONObject:event1 options:0 error:&error];
    NSData *json2 = [NSJSONSerialization dataWithJSONObject:event2 options:0 error:&error];

    NSString *fileName1 = [KeenTestUtils pathForEventInCollection:@"foo" WithTimestamp:[NSDate date]];
    NSString *fileName2 = [KeenTestUtils pathForEventInCollection:@"foo" WithTimestamp:[NSDate date]];

    [KeenTestUtils writeNSData:json1 toFile:fileName1];
    [KeenTestUtils writeNSData:json2 toFile:fileName2];

    [KIOFileStore importFileDataWithProjectID:kDefaultProjectID];
    // Now we're gonna add an event and verify the events we just wrote to the fs
    // are added to the database and the files are cleaned up.
    error = nil;
    NSDictionary *event3 = @{ @"nested": @{@"keen": @"whatever"} };
    [client addEvent:event3 toEventCollection:@"foo" error:nil];

    XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:client.config.projectID] == 3,
                  @"There should be 3 events after an import.");
    XCTAssertFalse([manager fileExistsAtPath:[KeenTestUtils keenDirectory] isDirectory:true],
                   @"The Keen directory should be gone.");
}

@end
