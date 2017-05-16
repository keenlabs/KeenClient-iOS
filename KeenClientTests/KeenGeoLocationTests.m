//
//  KeenGeoLocationTests.m
//  KeenClient
//
//  Created by Brian Baumhover on 5/8/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenClient.h"
#import "KeenClientTestable.h"
#import "KeenTestConstants.h"
#import "KeenGeoLocationTests.h"

@implementation KeenGeoLocationTests

- (void)testGeoLocation {
    // set up a client with a location
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    KeenClient *clientI = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                    andWriteKey:kDefaultWriteKey
                                                     andReadKey:kDefaultReadKey];

    CLLocation *location = [[CLLocation alloc] initWithLatitude:37.73 longitude:-122.47];
    client.currentLocation = location;
    clientI.currentLocation = location;
    // add an event
    [client addEvent:@{ @"a": @"b" } toEventCollection:@"foo" error:nil];
    [clientI addEvent:@{ @"a": @"b" } toEventCollection:@"foo" error:nil];
    // now get the stored event
    NSDictionary *eventsForCollection =
        [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID]
            objectForKey:@"foo"];
    // Grab the first event we get back
    NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
    NSError *error = nil;
    NSDictionary *deserializedDict = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:&error];

    NSDictionary *deserializedLocation = deserializedDict[@"keen"][@"location"];
    NSArray *deserializedCoords = deserializedLocation[@"coordinates"];
    XCTAssertEqualObjects(@-122.47, deserializedCoords[0], @"Longitude was incorrect.");
    XCTAssertEqualObjects(@37.73, deserializedCoords[1], @"Latitude was incorrect.");
}

- (void)testGeoLocationDisabled {
    // now try the same thing but disable geo location
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    KeenClient *clientI = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                    andWriteKey:kDefaultWriteKey
                                                     andReadKey:kDefaultReadKey];

    [KeenClient disableGeoLocation];
    // add an event
    [client addEvent:@{ @"a": @"b" } toEventCollection:@"bar" error:nil];
    [clientI addEvent:@{ @"a": @"b" } toEventCollection:@"bar" error:nil];
    // now get the stored event

    // Grab the first event we get back
    NSDictionary *eventsForCollection =
        [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID]
            objectForKey:@"bar"];
    // Grab the first event we get back
    NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
    NSError *error = nil;
    NSDictionary *deserializedDict = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:&error];

    NSDictionary *deserializedLocation = deserializedDict[@"keen"][@"location"];
    XCTAssertNil(deserializedLocation, @"No location should have been saved.");
}

- (void)testGeoLocationRequestDisabled {
    // now try the same thing but disable geo location
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    KeenClient *clientI = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                    andWriteKey:kDefaultWriteKey
                                                     andReadKey:kDefaultReadKey];

    [KeenClient disableGeoLocationDefaultRequest];
    // add an event
    [client addEvent:@{ @"a": @"b" } toEventCollection:@"bar" error:nil];
    [clientI addEvent:@{ @"a": @"b" } toEventCollection:@"bar" error:nil];
    // now get the stored event

    // Grab the first event we get back
    NSDictionary *eventsForCollection =
        [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID]
            objectForKey:@"bar"];
    // Grab the first event we get back
    NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
    NSError *error = nil;
    NSDictionary *deserializedDict = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:&error];

    NSDictionary *deserializedLocation = deserializedDict[@"keen"][@"location"];
    XCTAssertNil(deserializedLocation, @"No location should have been saved.");

    // To properly test this, you want to make sure that this triggers a real location authentication request,
    // to make sure that it returns a location.
}

@end
