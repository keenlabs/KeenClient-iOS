//
//  KeenClientTests.m
//  KeenClientTests
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenClientTests.h"
#import "KeenClient.h"
#import "KeenClientConfig.h"
#import <OCMock/OCMock.h>
#import "KeenConstants.h"
#import "KeenProperties.h"
#import "HTTPCodes.h"
#import "KIOUtil.h"
#import "KIOQuery.h"
#import "KIOFileStore.h"
#import "KIONetwork.h"
#import "KIOUploader.h"

#import "KeenTestUtils.h"
#import "KeenTestConstants.h"
#import "KeenClientTestable.h"
#import "KIONetworkTestable.h"
#import "KIOUploaderTestable.h"


@implementation KeenClientTests


- (void)testInitWithProjectID{
    KeenClient *client = [[KeenClient alloc] initWithProjectID:@"something" andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    XCTAssertEqualObjects(@"something", client.config.projectID, @"init with a valid project id should work");
    XCTAssertEqualObjects(kDefaultWriteKey, client.config.writeKey, @"init with a valid project id should work");
    XCTAssertEqualObjects(kDefaultReadKey, client.config.readKey, @"init with a valid project id should work");

    KeenClient *client2 = [[KeenClient alloc] initWithProjectID:@"another" andWriteKey:@"wk2" andReadKey:@"rk2"];
    XCTAssertEqualObjects(@"another", client2.config.projectID, @"init with a valid project id should work");
    XCTAssertEqualObjects(@"wk2", client2.config.writeKey, @"init with a valid project id should work");
    XCTAssertEqualObjects(@"rk2", client2.config.readKey, @"init with a valid project id should work");
    XCTAssertTrue(client != client2, @"Another init should return a separate instance");

    client = [[KeenClient alloc] initWithProjectID:nil andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    XCTAssertNil(client, @"init with a nil project ID should return nil");
}

- (void)testInstanceClient {
    KeenClient *client = [[KeenClient alloc] init];
    XCTAssertNil(client.config.projectID, @"a client's project id should be nil at first");
    XCTAssertNil(client.config.writeKey, @"a client's write key should be nil at first");
    XCTAssertNil(client.config.readKey, @"a client's read key should be nil at first");

    KeenClient *client2 = [[KeenClient alloc] init];
    XCTAssertTrue(client != client2, @"Another init should return a separate instance");
}

- (void)testSharedClientWithProjectID{
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    XCTAssertEqual(kDefaultProjectID, client.config.projectID, @"sharedClientWithProjectID with a non-nil project id should work.");
    XCTAssertEqualObjects(kDefaultWriteKey, client.config.writeKey, @"init with a valid project id should work");
    XCTAssertEqualObjects(kDefaultReadKey, client.config.readKey, @"init with a valid project id should work");

    KeenClient *client2 = [KeenClient sharedClientWithProjectID:@"other" andWriteKey:@"wk2" andReadKey:@"rk2"];
    XCTAssertEqualObjects(client, client2, @"sharedClient should return the same instance");
    XCTAssertEqualObjects(@"wk2", client2.config.writeKey, @"sharedClient with a valid project id should work");
    XCTAssertEqualObjects(@"rk2", client2.config.readKey, @"sharedClient with a valid project id should work");

    client = [KeenClient sharedClientWithProjectID:nil andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    XCTAssertNil(client, @"sharedClient with an invalid project id should return nil");
}

- (void)testSharedClient {
    KeenClient *client = [KeenClient sharedClient];
    XCTAssertNil(client.config.projectID, @"a client's project id should be nil at first");
    XCTAssertNil(client.config.writeKey, @"a client's write key should be nil at first");
    XCTAssertNil(client.config.readKey, @"a client's read key should be nil at first");

    KeenClient *client2 = [KeenClient sharedClient];
    XCTAssertEqualObjects(client, client2, @"sharedClient should return the same instance");
}

- (void)testBasicAddon {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    KeenClient *clientI = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];

    NSDictionary *theEvent = @{
                               @"keen":@{
                                       @"addons" : @[
                                               @{
                                                   @"name" : @"addon:name",
                                                   @"input" : @{@"param_name" : @"property_that_contains_param"},
                                                   @"output" : @"property.to.store.output"
                                                   }
                                               ]
                                       },
                               @"a": @"b"
                               };

    // add the event
    NSError *error = nil;
    [client addEvent:theEvent toEventCollection:@"foo" error:&error];
    [clientI addEvent:theEvent toEventCollection:@"foo" error:&error];
    XCTAssertNil(error, @"event should add");

    // Grab the first event we get back
    NSDictionary *eventsForCollection = [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID] objectForKey:@"foo"];
    // Grab the first event we get back
    NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
    NSDictionary *deserializedDict = [NSJSONSerialization JSONObjectWithData:eventData
                                                                     options:0
                                                                       error:&error];

    NSDictionary *deserializedAddon = deserializedDict[@"keen"][@"addons"][0];
    XCTAssertEqualObjects(@"addon:name", deserializedAddon[@"name"], @"Addon name should be right");
}



- (void)testGlobalPropertiesDictionary {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    NSDictionary * (^RunTest)(NSDictionary*, NSUInteger) = ^(NSDictionary *globalProperties,
                                                             NSUInteger expectedNumProperties) {
        NSString *eventCollectionName = [NSString stringWithFormat:@"foo%f", [[NSDate date] timeIntervalSince1970]];
        client.globalPropertiesDictionary = globalProperties;
        NSDictionary *event = @{@"foo": @"bar"};
        [client addEvent:event toEventCollection:eventCollectionName error:nil];
        NSDictionary *eventsForCollection = [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID] objectForKey:eventCollectionName];
        // Grab the first event we get back
        NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
        NSError *error = nil;
        NSDictionary *storedEvent = [NSJSONSerialization JSONObjectWithData:eventData
                                                                  options:0
                                                                    error:&error];

        XCTAssertEqualObjects(event[@"foo"], storedEvent[@"foo"]);
        XCTAssertEqual([storedEvent count], expectedNumProperties + 1, @"Stored event: %@", storedEvent);
        return storedEvent;
    };

    // a nil dictionary should be okay
    RunTest(nil, 1);

    // an empty dictionary should be okay
    RunTest(@{}, 1);

    // a dictionary that returns some non-conflicting property names should be okay
    NSDictionary *storedEvent = RunTest(@{@"default_name": @"default_value"}, 2);
    XCTAssertEqualObjects(@"default_value", storedEvent[@"default_name"], @"");

    // a dictionary that returns a conflicting property name should not overwrite the property on
    // the event
    RunTest(@{@"foo": @"some_new_value"}, 1);

    // a dictionary that contains an addon should be okay
    NSDictionary *theEvent = @{
                               @"keen":@{
                                       @"addons" : @[
                                               @{
                                                   @"name" : @"addon:name",
                                                   @"input" : @{@"param_name" : @"property_that_contains_param"},
                                                   @"output" : @"property.to.store.output"
                                                   }
                                               ]
                                       },
                               @"a": @"b"
                               };
    storedEvent = RunTest(theEvent, 2);
    NSDictionary *deserializedAddon = storedEvent[@"keen"][@"addons"][0];
    XCTAssertEqualObjects(@"addon:name", deserializedAddon[@"name"], @"Addon name should be right");
}

- (void)testGlobalPropertiesDictionaryInstanceClient {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    NSDictionary * (^RunTest)(NSDictionary*, NSUInteger) = ^(NSDictionary *globalProperties,
                                                             NSUInteger expectedNumProperties) {
        NSString *eventCollectionName = [NSString stringWithFormat:@"foo%f", [[NSDate date] timeIntervalSince1970]];
        client.globalPropertiesDictionary = globalProperties;
        NSDictionary *event = @{@"foo": @"bar"};
        [client addEvent:event toEventCollection:eventCollectionName error:nil];
        NSDictionary *eventsForCollection = [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID] objectForKey:eventCollectionName];
        // Grab the first event we get back
        NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
        NSError *error = nil;
        NSDictionary *storedEvent = [NSJSONSerialization JSONObjectWithData:eventData
                                                                    options:0
                                                                      error:&error];

        XCTAssertEqualObjects(event[@"foo"], storedEvent[@"foo"], @"");
        XCTAssertTrue([storedEvent count] == expectedNumProperties + 1, @"");
        return storedEvent;
    };

    // a nil dictionary should be okay
    RunTest(nil, 1);

    // an empty dictionary should be okay
    RunTest(@{}, 1);

    // a dictionary that returns some non-conflicting property names should be okay
    NSDictionary *storedEvent = RunTest(@{@"default_name": @"default_value"}, 2);
    XCTAssertEqualObjects(@"default_value", storedEvent[@"default_name"], @"");

    // a dictionary that returns a conflicting property name should not overwrite the property on
    // the event
    RunTest(@{@"foo": @"some_new_value"}, 1);

    // a dictionary that contains an addon should be okay
    NSDictionary *theEvent = @{
                               @"keen":@{
                                       @"addons" : @[
                                               @{
                                                   @"name" : @"addon:name",
                                                   @"input" : @{@"param_name" : @"property_that_contains_param"},
                                                   @"output" : @"property.to.store.output"
                                                   }
                                               ]
                                       },
                               @"a": @"b"
                               };
    storedEvent = RunTest(theEvent, 2);
    NSDictionary *deserializedAddon = storedEvent[@"keen"][@"addons"][0];
    XCTAssertEqualObjects(@"addon:name", deserializedAddon[@"name"], @"Addon name should be right");
}

- (void)testGlobalPropertiesBlock {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    NSDictionary * (^RunTest)(KeenGlobalPropertiesBlock, NSUInteger) = ^(KeenGlobalPropertiesBlock block,
                                                                         NSUInteger expectedNumProperties) {
        NSString *eventCollectionName = [NSString stringWithFormat:@"foo%f", [[NSDate date] timeIntervalSince1970]];
        client.globalPropertiesBlock = block;
        NSDictionary *event = @{@"foo": @"bar"};
        [client addEvent:event toEventCollection:eventCollectionName error:nil];

        NSDictionary *eventsForCollection = [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID] objectForKey:eventCollectionName];
        // Grab the first event we get back
        NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
        NSError *error = nil;
        NSDictionary *storedEvent = [NSJSONSerialization JSONObjectWithData:eventData
                                                                    options:0
                                                                      error:&error];

        XCTAssertEqualObjects(event[@"foo"], storedEvent[@"foo"], @"");
        XCTAssertTrue([storedEvent count] == expectedNumProperties + 1, @"");
        return storedEvent;
    };

    // a block that returns nil should be okay
    RunTest(nil, 1);

    // a block that returns an empty dictionary should be okay
    RunTest(^NSDictionary *(NSString *eventCollection) {
        return [NSDictionary dictionary];
    }, 1);

    // a block that returns some non-conflicting property names should be okay
    NSDictionary *storedEvent = RunTest(^NSDictionary *(NSString *eventCollection) {
        return @{@"default_name": @"default_value"};
    }, 2);
    XCTAssertEqualObjects(@"default_value", storedEvent[@"default_name"], @"");

    // a block that returns a conflicting property name should not overwrite the property on the event
    RunTest(^NSDictionary *(NSString *eventCollection) {
        return @{@"foo": @"some new value"};
    }, 1);

    // a dictionary that contains an addon should be okay
    NSDictionary *theEvent = @{
                               @"keen":@{
                                       @"addons" : @[
                                               @{
                                                   @"name" : @"addon:name",
                                                   @"input" : @{@"param_name" : @"property_that_contains_param"},
                                                   @"output" : @"property.to.store.output"
                                                   }
                                               ]
                                       },
                               @"a": @"b"
                               };
    storedEvent = RunTest(^NSDictionary *(NSString *eventCollection) {
        return theEvent;
    }, 2);
    NSDictionary *deserializedAddon = storedEvent[@"keen"][@"addons"][0];
    XCTAssertEqualObjects(@"addon:name", deserializedAddon[@"name"], @"Addon name should be right");
}

- (void)testGlobalPropertiesBlockInstanceClient {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    NSDictionary * (^RunTest)(KeenGlobalPropertiesBlock, NSUInteger) = ^(KeenGlobalPropertiesBlock block,
                                                                         NSUInteger expectedNumProperties) {
        NSString *eventCollectionName = [NSString stringWithFormat:@"foo%f", [[NSDate date] timeIntervalSince1970]];
        client.globalPropertiesBlock = block;
        NSDictionary *event = @{@"foo": @"bar"};
        [client addEvent:event toEventCollection:eventCollectionName error:nil];

        NSDictionary *eventsForCollection = [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID] objectForKey:eventCollectionName];
        // Grab the first event we get back
        NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
        NSError *error = nil;
        NSDictionary *storedEvent = [NSJSONSerialization JSONObjectWithData:eventData
                                                                    options:0
                                                                      error:&error];

        XCTAssertEqualObjects(event[@"foo"], storedEvent[@"foo"], @"");
        XCTAssertTrue([storedEvent count] == expectedNumProperties + 1, @"");
        return storedEvent;
    };

    // a block that returns nil should be okay
    RunTest(nil, 1);

    // a block that returns an empty dictionary should be okay
    RunTest(^NSDictionary *(NSString *eventCollection) {
        return [NSDictionary dictionary];
    }, 1);

    // a block that returns some non-conflicting property names should be okay
    NSDictionary *storedEvent = RunTest(^NSDictionary *(NSString *eventCollection) {
        return @{@"default_name": @"default_value"};
    }, 2);
    XCTAssertEqualObjects(@"default_value", storedEvent[@"default_name"], @"");

    // a block that returns a conflicting property name should not overwrite the property on the event
    RunTest(^NSDictionary *(NSString *eventCollection) {
        return @{@"foo": @"some new value"};
    }, 1);

    // a dictionary that contains an addon should be okay
    NSDictionary *theEvent = @{
                               @"keen":@{
                                       @"addons" : @[
                                               @{
                                                   @"name" : @"addon:name",
                                                   @"input" : @{@"param_name" : @"property_that_contains_param"},
                                                   @"output" : @"property.to.store.output"
                                                   }
                                               ]
                                       },
                               @"a": @"b"
                               };
    storedEvent = RunTest(^NSDictionary *(NSString *eventCollection) {
        return theEvent;
    }, 2);
    NSDictionary *deserializedAddon = storedEvent[@"keen"][@"addons"][0];
    XCTAssertEqualObjects(@"addon:name", deserializedAddon[@"name"], @"Addon name should be right");
}

- (void)testGlobalPropertiesTogether {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    // properties from the block should take precedence over properties from the dictionary
    // but properties from the event itself should take precedence over all
    client.globalPropertiesDictionary = @{@"default_property": @5, @"foo": @"some_new_value"};
    client.globalPropertiesBlock = ^NSDictionary *(NSString *eventCollection) {
        return @{ @"default_property": @6, @"foo": @"some_other_value"};
    };
    [client addEvent:@{@"foo": @"bar"} toEventCollection:@"apples" error:nil];

    NSDictionary *eventsForCollection = [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID] objectForKey:@"apples"];
    // Grab the first event we get back
    NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
    NSError *error = nil;
    NSDictionary *storedEvent = [NSJSONSerialization JSONObjectWithData:eventData
                                                                options:0
                                                                  error:&error];

    XCTAssertEqualObjects(@"bar", storedEvent[@"foo"], @"");
    XCTAssertEqualObjects(@6, storedEvent[@"default_property"], @"");
    XCTAssertTrue([storedEvent count] == 3, @"");
}

- (void)testGlobalPropertiesTogetherInstanceClient {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    // properties from the block should take precedence over properties from the dictionary
    // but properties from the event itself should take precedence over all
    client.globalPropertiesDictionary = @{@"default_property": @5, @"foo": @"some_new_value"};
    client.globalPropertiesBlock = ^NSDictionary *(NSString *eventCollection) {
        return @{ @"default_property": @6, @"foo": @"some_other_value"};
    };
    [client addEvent:@{@"foo": @"bar"} toEventCollection:@"apples" error:nil];

    NSDictionary *eventsForCollection = [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID] objectForKey:@"apples"];
    // Grab the first event we get back
    NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
    NSError *error = nil;
    NSDictionary *storedEvent = [NSJSONSerialization JSONObjectWithData:eventData
                                                                options:0
                                                                  error:&error];

    XCTAssertEqualObjects(@"bar", storedEvent[@"foo"], @"");
    XCTAssertEqualObjects(@6, storedEvent[@"default_property"], @"");
    XCTAssertTrue([storedEvent count] == 3, @"");
}

- (void)testInvalidEventCollection {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    NSDictionary *event = @{@"a": @"b"};
    // collection can't start with $
    NSError *error = nil;
    [client addEvent:event toEventCollection:@"$asd" error:&error];
    XCTAssertNotNil(error, @"collection can't start with $");
    error = nil;

    // collection can't be over 256 chars
    NSMutableString *longString = [NSMutableString stringWithCapacity:257];
    for (int i=0; i<257; i++) {
        [longString appendString:@"a"];
    }
    [client addEvent:event toEventCollection:@"$asd" error:&error];
    XCTAssertNotNil(error, @"collection can't be longer than 256 chars");
}

- (void)testInvalidEventCollectionInstanceClient {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    NSDictionary *event = @{@"a": @"b"};
    // collection can't start with $
    NSError *error = nil;
    [client addEvent:event toEventCollection:@"$asd" error:&error];
    XCTAssertNotNil(error, @"collection can't start with $");
    error = nil;

    // collection can't be over 256 chars
    NSMutableString *longString = [NSMutableString stringWithCapacity:257];
    for (int i=0; i<257; i++) {
        [longString appendString:@"a"];
    }
    [client addEvent:event toEventCollection:@"$asd" error:&error];
    XCTAssertNotNil(error, @"collection can't be longer than 256 chars");
}

- (void)testUploadMultipleTimes {
    XCTestExpectation* uploadFinishedBlockCalled1 = [self expectationWithDescription:@"Upload 1 should run to completion."];
    XCTestExpectation* uploadFinishedBlockCalled2 = [self expectationWithDescription:@"Upload 2 should run to completion."];
    XCTestExpectation* uploadFinishedBlockCalled3 = [self expectationWithDescription:@"Upload 3 should run to completion."];

    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    [client uploadWithFinishedBlock:^{
        [uploadFinishedBlockCalled1 fulfill];
    }];
    [client uploadWithFinishedBlock:^{
        [uploadFinishedBlockCalled2 fulfill];
    }];
    [client uploadWithFinishedBlock:^ {
        [uploadFinishedBlockCalled3 fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testUploadMultipleTimesInstanceClient {
    XCTestExpectation* uploadFinishedBlockCalled1 = [self expectationWithDescription:@"Upload 1 should run to completion."];
    XCTestExpectation* uploadFinishedBlockCalled2 = [self expectationWithDescription:@"Upload 2 should run to completion."];
    XCTestExpectation* uploadFinishedBlockCalled3 = [self expectationWithDescription:@"Upload 3 should run to completion."];

    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    [client uploadWithFinishedBlock:^{
        [uploadFinishedBlockCalled1 fulfill];
    }];
    [client uploadWithFinishedBlock:^{
        [uploadFinishedBlockCalled2 fulfill];
    }];
    [client uploadWithFinishedBlock:^ {
        [uploadFinishedBlockCalled3 fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testMigrateFSEvents {

    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
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
    NSData *json2 =[NSJSONSerialization dataWithJSONObject:event2 options:0 error:&error];

    NSString *fileName1 = [KeenTestUtils pathForEventInCollection:@"foo" WithTimestamp:[NSDate date]];
    NSString *fileName2 = [KeenTestUtils pathForEventInCollection:@"foo" WithTimestamp:[NSDate date]];

    [KeenTestUtils writeNSData:json1 toFile:fileName1];
    [KeenTestUtils writeNSData:json2 toFile:fileName2];

    [KIOFileStore importFileDataWithProjectID:kDefaultProjectID];
    // Now we're gonna add an event and verify the events we just wrote to the fs
    // are added to the database and the files are cleaned up.
    error = nil;
    NSDictionary *event3 = @{@"nested": @{@"keen": @"whatever"}};
    [client addEvent:event3 toEventCollection:@"foo" error:nil];

    XCTAssertEqual(3,
                   [KIODBStore.sharedInstance getTotalEventCountWithProjectID:client.config.projectID],
                   @"There should be 3 events after an import.");
    XCTAssertFalse([manager fileExistsAtPath:[KeenTestUtils keenDirectory] isDirectory:true],
                   @"The Keen directory should be gone.");
}

- (void)testMigrateFSEventsInstanceClient {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
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
    NSData *json2 =[NSJSONSerialization dataWithJSONObject:event2 options:0 error:&error];

    NSString *fileName1 = [KeenTestUtils pathForEventInCollection:@"foo" WithTimestamp:[NSDate date]];
    NSString *fileName2 = [KeenTestUtils pathForEventInCollection:@"foo" WithTimestamp:[NSDate date]];

    [KeenTestUtils writeNSData:json1 toFile:fileName1];
    [KeenTestUtils writeNSData:json2 toFile:fileName2];

    [KIOFileStore importFileDataWithProjectID:kDefaultProjectID];
    // Now we're gonna add an event and verify the events we just wrote to the fs
    // are added to the database and the files are cleaned up.
    error = nil;
    NSDictionary *event3 = @{@"nested": @{@"keen": @"whatever"}};
    [client addEvent:event3 toEventCollection:@"foo" error:nil];

    XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:client.config.projectID] == 3,  @"There should be 3 events after an import.");
    XCTAssertFalse([manager fileExistsAtPath:[KeenTestUtils keenDirectory] isDirectory:true], @"The Keen directory should be gone.");
}

- (void)testSDKVersion {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    // result from class method should equal the SDK Version constant
    XCTAssertTrue([[KeenClient sdkVersion] isEqual:kKeenSdkVersion],  @"SDK Version from class method equals the SDK Version constant.");
    XCTAssertFalse(![[KeenClient sdkVersion] isEqual:kKeenSdkVersion], @"SDK Version from class method doesn't equal the SDK Version constant.");
}

- (void)testSDKVersionInstanceClient {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    // result from class method should equal the SDK Version constant
    XCTAssertTrue([[KeenClient sdkVersion] isEqual:kKeenSdkVersion],  @"SDK Version from class method equals the SDK Version constant.");
    XCTAssertFalse(![[KeenClient sdkVersion] isEqual:kKeenSdkVersion], @"SDK Version from class method doesn't equal the SDK Version constant.");
}

# pragma mark - test query

- (void)testCountQueryFailure {
    XCTestExpectation* queryCompleted = [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{} andStatusCode:HTTPCode5XXServerError];

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{}];

    [mock runAsyncQuery:query completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
        KCLogInfo(@"error: %@", error);
        KCLogInfo(@"response: %@", response);

        XCTAssertNil(error);

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
        XCTAssertEqual([httpResponse statusCode], HTTPCode5XXServerError);

        NSDictionary *responseDictionary = [NSJSONSerialization
                                            JSONObjectWithData:queryResponseData
                                            options:kNilOptions
                                            error:&error];

        KCLogInfo(@"response: %@", responseDictionary);

        NSNumber *result = [responseDictionary objectForKey:@"result"];

        XCTAssertNil(result);

        [queryCompleted fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testCountQuerySuccess {
    XCTestExpectation* queryCompleted = [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{@"result": @10} andStatusCode:HTTPCode200OK];

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"event_collection"}];

    [mock runAsyncQuery:query completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
        KCLogInfo(@"error: %@", error);
        KCLogInfo(@"response: %@", response);

        XCTAssertNil(error);

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
        XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

        NSDictionary *responseDictionary = [NSJSONSerialization
                                            JSONObjectWithData:queryResponseData
                                            options:kNilOptions
                                            error:&error];

        KCLogInfo(@"response: %@", responseDictionary);

        NSNumber *result = [responseDictionary objectForKey:@"result"];

        XCTAssertEqual(result, [NSNumber numberWithInt:10]);

        [queryCompleted fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testCountQuerySuccessWithGroupByProperty {
    XCTestExpectation* queryCompleted = [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{@"result": @[@{ @"result": @10, @"key": @"value" }]} andStatusCode:HTTPCode200OK];

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"event_collection",
                                                                                         @"group_by": @"key"}];

    [mock runAsyncQuery:query completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
        KCLogInfo(@"error: %@", error);
        KCLogInfo(@"response: %@", response);

        XCTAssertNil(error);

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
        XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

        NSDictionary *responseDictionary = [NSJSONSerialization
                                            JSONObjectWithData:queryResponseData
                                            options:kNilOptions
                                            error:&error];

        KCLogInfo(@"response: %@", responseDictionary);

        NSNumber *result = [[responseDictionary objectForKey:@"result"][0] objectForKey:@"result"];

        XCTAssertEqual(result, [NSNumber numberWithInt:10]);
        [queryCompleted fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testCountQuerySuccessWithTimeframeAndIntervalProperties {
    XCTestExpectation* queryCompleted = [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{@"result": @[@{@"value": @10,
                                                         @"timeframe": @{@"start": @"2015-06-19T00:00:00.000Z",
                                                                         @"end": @"2015-06-20T00:00:00.000Z"} }]} andStatusCode:HTTPCode200OK];

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"event_collection",
                                                       @"interval": @"daily",
                                                       @"timeframe": @"last_1_days"}];

    [mock runAsyncQuery:query completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
        KCLogInfo(@"error: %@", error);
        KCLogInfo(@"response: %@", response);

        XCTAssertNil(error);

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
        XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

        NSDictionary *responseDictionary = [NSJSONSerialization
                                            JSONObjectWithData:queryResponseData
                                            options:kNilOptions
                                            error:&error];

        KCLogInfo(@"response: %@", responseDictionary);

        NSNumber *result = [[responseDictionary objectForKey:@"result"][0] objectForKey:@"value"];

        XCTAssertEqual(result, [NSNumber numberWithInt:10]);

        [queryCompleted fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testCountUniqueQueryWithMissingTargetProperty {
    XCTestExpectation* queryCompleted = [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{} andStatusCode:HTTPCode400BadRequest];

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"event_collection"}];

    [mock runAsyncQuery:query completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
        KCLogInfo(@"error: %@", error);
        KCLogInfo(@"response: %@", response);

        XCTAssertNil(error);

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
        XCTAssertEqual([httpResponse statusCode], HTTPCode400BadRequest);

        NSDictionary *responseDictionary = [NSJSONSerialization
                                            JSONObjectWithData:queryResponseData
                                            options:kNilOptions
                                            error:&error];

        KCLogInfo(@"response: %@", responseDictionary);

        NSNumber *result = [responseDictionary objectForKey:@"result"];

        XCTAssertNil(result);

        [queryCompleted fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testCountUniqueQuerySuccess {
    XCTestExpectation* queryCompleted = [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{@"result": @10} andStatusCode:HTTPCode200OK];

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"event_collection", @"target_property": @"something"}];

    [mock runAsyncQuery:query completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
        KCLogInfo(@"error: %@", error);
        KCLogInfo(@"response: %@", response);

        XCTAssertNil(error);

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
        XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

        NSDictionary *responseDictionary = [NSJSONSerialization
                                            JSONObjectWithData:queryResponseData
                                            options:kNilOptions
                                            error:&error];

        KCLogInfo(@"response: %@", responseDictionary);

        NSNumber *result = [responseDictionary objectForKey:@"result"];

        XCTAssertEqual(result, [NSNumber numberWithInt:10]);

        [queryCompleted fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testMultiAnalysisSuccess {
    XCTestExpectation* queryCompleted = [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{@"result": @{@"query1": @10, @"query2": @1}} andStatusCode:HTTPCode200OK];

    KIOQuery *countQuery = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"event_collection"}];

    KIOQuery *averageQuery = [[KIOQuery alloc] initWithQuery:@"count_unique" andPropertiesDictionary:@{@"event_collection": @"event_collection", @"target_property": @"something"}];

    [mock runAsyncMultiAnalysisWithQueries:@[countQuery, averageQuery]
                         completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
        KCLogInfo(@"error: %@", error);
        KCLogInfo(@"response: %@", response);

        XCTAssertNil(error);

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
        XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

        NSDictionary *responseDictionary = [NSJSONSerialization
                                            JSONObjectWithData:queryResponseData
                                            options:kNilOptions
                                            error:&error];

        KCLogInfo(@"response: %@", responseDictionary);

        NSNumber *result = [[responseDictionary objectForKey:@"result"] objectForKey:@"query1"];

        XCTAssertEqual(result, [NSNumber numberWithInt:10]);

        [queryCompleted fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testFunnelQuerySuccess {
    XCTestExpectation* queryCompleted = [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{@"result": @[@10, @5],
                                          @"steps":@[@{@"actor_property": @[@"user.id"],
                                                       @"event_collection": @"user_signed_up"},
                                                     @{@"actor_property": @[@"user.id"],
                                                       @"event_collection": @"user_completed_profile"}]} andStatusCode:HTTPCode200OK];

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"funnel" andPropertiesDictionary:@{@"steps": @[@{@"event_collection": @"user_signed_up", @"actor_property": @"user.id"},
                                                                                                      @{@"event_collection": @"user_completed_profile", @"actor_property": @"user.id"}]}];

    [mock runAsyncQuery:query completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
        KCLogInfo(@"error: %@", error);
        KCLogInfo(@"response: %@", response);

        XCTAssertNil(error);

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
        XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

        NSDictionary *responseDictionary = [NSJSONSerialization
                                            JSONObjectWithData:queryResponseData
                                            options:kNilOptions
                                            error:&error];

        KCLogInfo(@"response: %@", responseDictionary);

        NSArray *result = [responseDictionary objectForKey:@"result"];
        NSArray *resultArray = @[@10, @5];

        KCLogInfo(@"result: %@", [result class]);
        KCLogInfo(@"resultArray: %@", [resultArray class]);

        XCTAssertEqual([result count], (NSUInteger)2);
        XCTAssertEqualObjects(result, resultArray);
        [queryCompleted fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void) testSuccessfulQueryAPIResponse {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"url"]
                                                              statusCode:HTTPCode2XXSuccess
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:@{}];
    NSData *responseData = [@"query failed" dataUsingEncoding:NSUTF8StringEncoding];

    [client.network handleQueryAPIResponse:response
                                   andData:responseData
                                  andQuery:nil
                              andProjectID:kDefaultProjectID];

    // test that there are no entries in the query database
    XCTAssertEqual([KIODBStore.sharedInstance getTotalQueryCountWithProjectID:kDefaultProjectID],
                   (NSUInteger)0,
                   @"There should be no queries after a successful query API call");
}

- (void) testFailedQueryAPIResponse {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"url"]
                                                              statusCode:HTTPCode4XXClientError
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:@{}];
    NSData *responseData = [@"query failed" dataUsingEncoding:NSUTF8StringEncoding];

    // test that there is 1 entry in the query database after a failed query API call
    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count"
                              andPropertiesDictionary:@{@"event_collection": @"collection"}];

    [client.network handleQueryAPIResponse:response
                           andData:responseData
                          andQuery:query
                      andProjectID:kDefaultProjectID];

    NSUInteger numberOfQueries = [KIODBStore.sharedInstance getTotalQueryCountWithProjectID:kDefaultProjectID];

    XCTAssertEqual(numberOfQueries,
                   (NSUInteger)1,
                   @"There should be 1 query in the database after a failed query API call");

    // test that there are 2 entries in the query database after two failed different query API calls
    KIOQuery *query2 = [[KIOQuery alloc] initWithQuery:@"count"
                               andPropertiesDictionary:@{@"event_collection": @"collection2"}];

    [client.network handleQueryAPIResponse:response
                                   andData:responseData
                                  andQuery:query2
                              andProjectID:kDefaultProjectID];

    numberOfQueries = [KIODBStore.sharedInstance getTotalQueryCountWithProjectID:kDefaultProjectID];
    XCTAssertEqual(numberOfQueries,
                   (NSUInteger)2,
                   @"There should be 2 queries in the database after two failed query API calls");

    // test that there is still 2 entries in the query database after the same query fails twice
    [client.network handleQueryAPIResponse:response
                                   andData:responseData
                                  andQuery:query2
                              andProjectID:kDefaultProjectID];

    numberOfQueries = [KIODBStore.sharedInstance getTotalQueryCountWithProjectID:kDefaultProjectID];
    XCTAssertEqual(numberOfQueries,
                   (NSUInteger)2,
                   @"There should still be 2 queries in the database after two of the same failed query API call");
}

- (void)validateSdkVersionHeaderFieldForRequest:(id)requestObject {
    XCTAssertTrue([requestObject isKindOfClass:[NSMutableURLRequest class]]);
    NSMutableURLRequest* request = requestObject;
    NSString* versionInfo = [request valueForHTTPHeaderField:kKeenSdkVersionHeader];
    XCTAssertNotNil(versionInfo, @"Request should have included SDK info header.");
    NSRange platformRange = [versionInfo rangeOfString:@"ios-"];
    XCTAssertEqual(platformRange.location, 0, @"SDK info header should start with the platform.");
    XCTAssertEqual(platformRange.length, 4, @"Unexpected SDK platform info.");
    NSRange versionRange = [versionInfo rangeOfString:kKeenSdkVersion];
    XCTAssertEqual(versionRange.location, 4, @"SDK version should be included in SDK platform info.");
}

- (void)testSdkTrackingHeadersOnUpload {
    // mock an empty response from the server

    KeenClient* client = [self createClientWithRequestValidator:^BOOL(id obj) {
        [self validateSdkVersionHeaderFieldForRequest:obj];
        return @YES;
    }];

    // Get the mock url session. We'll check the request it gets passed by sendEvents for the version header
    id urlSessionMock = client.network.urlSession;

    // add an event
    [client addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];

    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    // and "upload" it
    [client uploadWithFinishedBlock:^{
        // Check for the sdk version header
        [urlSessionMock verify];

        [responseArrived fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"Test should complete within expected interval.");
    }];
}

- (void)testSdkTrackingHeadersOnQuery {
    KeenClient* client = [self createClientWithResponseData:@{@"result": @10}
                                              andStatusCode:HTTPCode200OK
                                        andNetworkConnected:@YES
                                        andRequestValidator:^BOOL(id obj) {
        [self validateSdkVersionHeaderFieldForRequest:obj];
        return @YES;
    }];

    // Get the mock url session. We'll check the request it gets passed by sendEvents for the version header
    id urlSessionMock = client.network.urlSession;

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"event_collection"}];

    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [client runAsyncQuery:query completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
        // Check for the sdk version header
        [urlSessionMock verify];

        [responseArrived fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"Test should complete within expected interval.");
    }];
}

- (void)testSdkTrackingHeadersOnMultiAnalysis {
    KeenClient* client = [self createClientWithResponseData:@{@"result": @{@"query1": @10, @"query2": @1}}
                                              andStatusCode:HTTPCode200OK
                                        andNetworkConnected:@YES
                                        andRequestValidator:^BOOL(id obj) {
        [self validateSdkVersionHeaderFieldForRequest:obj];
        return @YES;
    }];

    // Get the mock url session. We'll check the request it gets passed by sendEvents for the version header
    id urlSessionMock = client.network.urlSession;

    KIOQuery* countQuery = [[KIOQuery alloc] initWithQuery:@"count"
                                   andPropertiesDictionary:@{@"event_collection": @"event_collection"}];

    KIOQuery* averageQuery = [[KIOQuery alloc] initWithQuery:@"count_unique"
                                     andPropertiesDictionary:@{@"event_collection": @"event_collection", @"target_property": @"something"}];

    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [client runAsyncMultiAnalysisWithQueries:@[countQuery, averageQuery]
                           completionHandler:^(NSData* queryResponseData, NSURLResponse* response, NSError* error) {
        // Check for the sdk version header
        [urlSessionMock verify];

        [responseArrived fulfill];
    }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"Test should complete within expected interval.");
    }];
}


@end
