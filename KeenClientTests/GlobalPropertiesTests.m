//
//  GlobalPropertiesTests.m
//  KeenClient
//
//  Created by Brian Baumhover on 5/9/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenClient.h"

#import "KeenTestConstants.h"
#import "KeenConstants.h"
#import "KeenClientTestable.h"

#import "GlobalPropertiesTests.h"

@implementation GlobalPropertiesTests

- (void)testGlobalPropertiesDictionary {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    NSDictionary * (^RunTest)(NSDictionary *, NSUInteger) =
        ^(NSDictionary *globalProperties, NSUInteger expectedNumProperties) {
            NSString *eventCollectionName = [NSString stringWithFormat:@"foo%f", [[NSDate date] timeIntervalSince1970]];
            client.globalPropertiesDictionary = globalProperties;
            NSDictionary *event = @{ @"foo": @"bar" };
            [client addEvent:event toEventCollection:eventCollectionName error:nil];
            NSDictionary *eventsForCollection =
                [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID]
                    objectForKey:eventCollectionName];
            // Grab the first event we get back
            NSData *eventData = eventsForCollection[[eventsForCollection allKeys][0]][@"data"];
            NSError *error = nil;
            NSDictionary *storedEvent = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:&error];

            XCTAssertEqualObjects(event[@"foo"], storedEvent[@"foo"]);
            XCTAssertEqual([storedEvent count], expectedNumProperties + 1, @"Stored event: %@", storedEvent);
            return storedEvent;
        };

    // a nil dictionary should be okay
    RunTest(nil, 1);

    // an empty dictionary should be okay
    RunTest(@{}, 1);

    // a dictionary that returns some non-conflicting property names should be okay
    NSDictionary *storedEvent = RunTest(@{ @"default_name": @"default_value" }, 2);
    XCTAssertEqualObjects(@"default_value", storedEvent[@"default_name"], @"");

    // a dictionary that returns a conflicting property name should not overwrite the property on
    // the event
    RunTest(@{ @"foo": @"some_new_value" }, 1);

    // a dictionary that contains an addon should be okay
    NSDictionary *theEvent = @{
        kKeenEventKeenDataKey: @{
            @"addons": @[@{
                @"name": @"addon:name",
                @"input": @{@"param_name": @"property_that_contains_param"},
                @"output": @"property.to.store.output"
            }]
        },
        @"a": @"b"
    };
    storedEvent = RunTest(theEvent, 2);
    NSDictionary *deserializedAddon = storedEvent[kKeenEventKeenDataKey][@"addons"][0];
    XCTAssertEqualObjects(@"addon:name", deserializedAddon[@"name"], @"Addon name should be right");
}

- (void)testGlobalPropertiesDictionaryInstanceClient {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    NSDictionary * (^RunTest)(NSDictionary *, NSUInteger) =
        ^(NSDictionary *globalProperties, NSUInteger expectedNumProperties) {
            NSString *eventCollectionName = [NSString stringWithFormat:@"foo%f", [[NSDate date] timeIntervalSince1970]];
            client.globalPropertiesDictionary = globalProperties;
            NSDictionary *event = @{ @"foo": @"bar" };
            [client addEvent:event toEventCollection:eventCollectionName error:nil];
            NSDictionary *eventsForCollection =
                [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID]
                    objectForKey:eventCollectionName];
            // Grab the first event we get back
            NSData *eventData = eventsForCollection[[eventsForCollection allKeys][0]][@"data"];
            NSError *error = nil;
            NSDictionary *storedEvent = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:&error];

            XCTAssertEqualObjects(event[@"foo"], storedEvent[@"foo"], @"");
            XCTAssertTrue([storedEvent count] == expectedNumProperties + 1, @"");
            return storedEvent;
        };

    // a nil dictionary should be okay
    RunTest(nil, 1);

    // an empty dictionary should be okay
    RunTest(@{}, 1);

    // a dictionary that returns some non-conflicting property names should be okay
    NSDictionary *storedEvent = RunTest(@{ @"default_name": @"default_value" }, 2);
    XCTAssertEqualObjects(@"default_value", storedEvent[@"default_name"], @"");

    // a dictionary that returns a conflicting property name should not overwrite the property on
    // the event
    RunTest(@{ @"foo": @"some_new_value" }, 1);

    // a dictionary that contains an addon should be okay
    NSDictionary *theEvent = @{
        kKeenEventKeenDataKey: @{
            @"addons": @[@{
                @"name": @"addon:name",
                @"input": @{@"param_name": @"property_that_contains_param"},
                @"output": @"property.to.store.output"
            }]
        },
        @"a": @"b"
    };
    storedEvent = RunTest(theEvent, 2);
    NSDictionary *deserializedAddon = storedEvent[kKeenEventKeenDataKey][@"addons"][0];
    XCTAssertEqualObjects(@"addon:name", deserializedAddon[@"name"], @"Addon name should be right");
}

- (void)testGlobalPropertiesBlock {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    NSDictionary * (^RunTest)(KeenGlobalPropertiesBlock, NSUInteger) =
        ^(KeenGlobalPropertiesBlock block, NSUInteger expectedNumProperties) {
            NSString *eventCollectionName = [NSString stringWithFormat:@"foo%f", [[NSDate date] timeIntervalSince1970]];
            client.globalPropertiesBlock = block;
            NSDictionary *event = @{ @"foo": @"bar" };
            [client addEvent:event toEventCollection:eventCollectionName error:nil];

            NSDictionary *eventsForCollection =
                [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID]
                    objectForKey:eventCollectionName];
            // Grab the first event we get back
            NSData *eventData = eventsForCollection[[eventsForCollection allKeys][0]][@"data"];
            NSError *error = nil;
            NSDictionary *storedEvent = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:&error];

            XCTAssertEqualObjects(event[@"foo"], storedEvent[@"foo"], @"");
            XCTAssertTrue([storedEvent count] == expectedNumProperties + 1, @"");
            return storedEvent;
        };

    // a block that returns nil should be okay
    RunTest(nil, 1);

    // a block that returns an empty dictionary should be okay
    RunTest(
        ^NSDictionary *(NSString *eventCollection) {
            return [NSDictionary dictionary];
        },
        1);

    // a block that returns some non-conflicting property names should be okay
    NSDictionary *storedEvent = RunTest(
        ^NSDictionary *(NSString *eventCollection) {
            return @{ @"default_name": @"default_value" };
        },
        2);
    XCTAssertEqualObjects(@"default_value", storedEvent[@"default_name"], @"");

    // a block that returns a conflicting property name should not overwrite the property on the event
    RunTest(
        ^NSDictionary *(NSString *eventCollection) {
            return @{ @"foo": @"some new value" };
        },
        1);

    // a dictionary that contains an addon should be okay
    NSDictionary *theEvent = @{
        kKeenEventKeenDataKey: @{
            @"addons": @[@{
                @"name": @"addon:name",
                @"input": @{@"param_name": @"property_that_contains_param"},
                @"output": @"property.to.store.output"
            }]
        },
        @"a": @"b"
    };
    storedEvent = RunTest(
        ^NSDictionary *(NSString *eventCollection) {
            return theEvent;
        },
        2);
    NSDictionary *deserializedAddon = storedEvent[kKeenEventKeenDataKey][@"addons"][0];
    XCTAssertEqualObjects(@"addon:name", deserializedAddon[@"name"], @"Addon name should be right");
}

- (void)testGlobalPropertiesBlockInstanceClient {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    NSDictionary * (^RunTest)(KeenGlobalPropertiesBlock, NSUInteger) =
        ^(KeenGlobalPropertiesBlock block, NSUInteger expectedNumProperties) {
            NSString *eventCollectionName = [NSString stringWithFormat:@"foo%f", [[NSDate date] timeIntervalSince1970]];
            client.globalPropertiesBlock = block;
            NSDictionary *event = @{ @"foo": @"bar" };
            [client addEvent:event toEventCollection:eventCollectionName error:nil];

            NSDictionary *eventsForCollection =
                [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID]
                    objectForKey:eventCollectionName];
            // Grab the first event we get back
            NSData *eventData = eventsForCollection[[eventsForCollection allKeys][0]][@"data"];
            NSError *error = nil;
            NSDictionary *storedEvent = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:&error];

            XCTAssertEqualObjects(event[@"foo"], storedEvent[@"foo"], @"");
            XCTAssertTrue([storedEvent count] == expectedNumProperties + 1, @"");
            return storedEvent;
        };

    // a block that returns nil should be okay
    RunTest(nil, 1);

    // a block that returns an empty dictionary should be okay
    RunTest(
        ^NSDictionary *(NSString *eventCollection) {
            return [NSDictionary dictionary];
        },
        1);

    // a block that returns some non-conflicting property names should be okay
    NSDictionary *storedEvent = RunTest(
        ^NSDictionary *(NSString *eventCollection) {
            return @{ @"default_name": @"default_value" };
        },
        2);
    XCTAssertEqualObjects(@"default_value", storedEvent[@"default_name"], @"");

    // a block that returns a conflicting property name should not overwrite the property on the event
    RunTest(
        ^NSDictionary *(NSString *eventCollection) {
            return @{ @"foo": @"some new value" };
        },
        1);

    // a dictionary that contains an addon should be okay
    NSDictionary *theEvent = @{
        kKeenEventKeenDataKey: @{
            @"addons": @[@{
                @"name": @"addon:name",
                @"input": @{@"param_name": @"property_that_contains_param"},
                @"output": @"property.to.store.output"
            }]
        },
        @"a": @"b"
    };
    storedEvent = RunTest(
        ^NSDictionary *(NSString *eventCollection) {
            return theEvent;
        },
        2);
    NSDictionary *deserializedAddon = storedEvent[kKeenEventKeenDataKey][@"addons"][0];
    XCTAssertEqualObjects(@"addon:name", deserializedAddon[@"name"], @"Addon name should be right");
}

- (void)testGlobalPropertiesTogether {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    // properties from the block should take precedence over properties from the dictionary
    // but properties from the event itself should take precedence over all
    client.globalPropertiesDictionary = @{ @"default_property": @5, @"foo": @"some_new_value" };
    client.globalPropertiesBlock = ^NSDictionary *(NSString *eventCollection) {
        return @{ @"default_property": @6, @"foo": @"some_other_value" };
    };
    [client addEvent:@{ @"foo": @"bar" } toEventCollection:@"apples" error:nil];

    NSDictionary *eventsForCollection =
        [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID]
            objectForKey:@"apples"];
    // Grab the first event we get back
    NSData *eventData = eventsForCollection[[eventsForCollection allKeys][0]][@"data"];
    NSError *error = nil;
    NSDictionary *storedEvent = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:&error];

    XCTAssertEqualObjects(@"bar", storedEvent[@"foo"], @"");
    XCTAssertEqualObjects(@6, storedEvent[@"default_property"], @"");
    XCTAssertTrue([storedEvent count] == 3, @"");
}

- (void)testGlobalPropertiesTogetherInstanceClient {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    // properties from the block should take precedence over properties from the dictionary
    // but properties from the event itself should take precedence over all
    client.globalPropertiesDictionary = @{ @"default_property": @5, @"foo": @"some_new_value" };
    client.globalPropertiesBlock = ^NSDictionary *(NSString *eventCollection) {
        return @{ @"default_property": @6, @"foo": @"some_other_value" };
    };
    [client addEvent:@{ @"foo": @"bar" } toEventCollection:@"apples" error:nil];

    NSDictionary *eventsForCollection =
        [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID]
            objectForKey:@"apples"];
    // Grab the first event we get back
    NSData *eventData = eventsForCollection[[eventsForCollection allKeys][0]][@"data"];
    NSError *error = nil;
    NSDictionary *storedEvent = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:&error];

    XCTAssertEqualObjects(@"bar", storedEvent[@"foo"], @"");
    XCTAssertEqualObjects(@6, storedEvent[@"default_property"], @"");
    XCTAssertTrue([storedEvent count] == 3, @"");
}

@end
