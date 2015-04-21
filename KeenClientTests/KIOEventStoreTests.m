//
//  KIOEventStoreTests.m
//  KeenClient
//
//  Created by Cory Watson on 3/26/14.
//  Copyright (c) 2014 Keen Labs. All rights reserved.
//

#import "KIOEventStore.h"
#import "KIOEventStoreTests.h"
#import "KIOEventStore_PrivateMethods.h"

@interface KIOEventStoreTests ()

- (NSString *)databaseFile;

@end

@implementation KIOEventStoreTests

- (void)setUp {
    // Clean up, just in case.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager removeItemAtPath:[self databaseFile] error:NULL] == YES) {
        NSLog(@"Removed database file.");
    } else {
        NSLog(@"Failed to remove database file.");
    }

    [super setUp];
}

- (void)tearDown {
    // Tear-down code here.
    NSLog(@"\n");

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager removeItemAtPath:[self databaseFile] error:NULL] == YES) {
        NSLog(@"Removed database file.");
    } else {
        NSLog(@"Failed to remove database file.");
    }

    [super tearDown];
}

- (void)testInit{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    XCTAssertNotNil(store, @"init is not null");
    NSString *dbPath = [self databaseFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    XCTAssertTrue([fileManager fileExistsAtPath:dbPath], @"Database file exists.");
}

- (void)testAdd{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    XCTAssertTrue([store getTotalEventCount] == 1, @"1 total event after add");
    XCTAssertTrue([store getPendingEventCount] == 0, @"0 pending events after add");
}

- (void)testDelete{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    XCTAssertTrue([store getTotalEventCount] == 1, @"1 total event after add");
    XCTAssertTrue([store getPendingEventCount] == 0, @"0 pending events after add");

    // Lets get some events out now with the purpose of deleteting them.
    NSMutableDictionary *events = [store getEventsWithMaxAttempts:3];
    XCTAssertTrue([store getPendingEventCount] == 1, @"1 pending events after getEvents");

    for (NSString *coll in events) {
        for (NSNumber *eid in [events objectForKey:coll]) {
            [store deleteEvent:eid];
        }
    }

    XCTAssertTrue([store getTotalEventCount] == 0, @"0 total events after delete");
    XCTAssertTrue([store getPendingEventCount] == 0, @"0 pending events after delete");
}

- (void)testGetPending{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];

    // Lets get some events out now with the purpose of sending them off.
    NSMutableDictionary *events = [store getEventsWithMaxAttempts:3];

    XCTAssertTrue([events count] == 1, @"1 collection returned");
    XCTAssertTrue([[events objectForKey:@"foo"] count] == 2, @"2 events returned");

    XCTAssertTrue([store getTotalEventCount] == 2, @"2 total event after add");
    XCTAssertTrue([store getPendingEventCount] == 2, @"2 pending event after add");
    XCTAssertTrue([store hasPendingEvents], @"has pending events!");

    [store addEvent:[@"I AM NOT AN EVENT BUT A STRING" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    XCTAssertTrue([store getTotalEventCount] == 3, @"3 total event after non-pending add");
    XCTAssertTrue([store getPendingEventCount] == 2, @"2 pending event after add");
}

- (void)testCleanupOfPending{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];

    // Lets get some events out now with the purpose of sending them off.
    [store getEventsWithMaxAttempts:3];

    [store purgePendingEvents];
    XCTAssertTrue([store getTotalEventCount] == 0, @"0 total event after add");
    XCTAssertFalse([store hasPendingEvents], @"No pending events now!");

    // Again for good measure
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];

    [store getEventsWithMaxAttempts:3];

    [store purgePendingEvents];
    XCTAssertTrue([store getTotalEventCount] == 0, @"0 total event after add");
    XCTAssertFalse([store hasPendingEvents], @"No pending events now!");
}

- (void)testResetOfPending{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];

    // Lets get some events out now with the purpose of sending them off.
    [store getEventsWithMaxAttempts:3];
    XCTAssertTrue([store getTotalEventCount] == 2, @"2 total event after add");
    XCTAssertTrue([store getPendingEventCount] == 2, @"2 pending event after add");
    XCTAssertTrue([store hasPendingEvents], @"has pending events!");

    [store resetPendingEvents];
    XCTAssertTrue([store getTotalEventCount] == 2, @"0 total event after reset");
    XCTAssertTrue([store getPendingEventCount] == 0, @"2 pending event after reset");
    XCTAssertFalse([store hasPendingEvents], @"has NO pending events!");

    // Again for good measure
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];

    [store getEventsWithMaxAttempts:3];

    [store resetPendingEvents];
    XCTAssertTrue([store getTotalEventCount] == 4, @"0 total event after add");
    XCTAssertFalse([store hasPendingEvents], @"No pending events now!");
}

- (void)testDeleteFromOffset{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN BUT ANOTHER EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];

    [store deleteEventsFromOffset:@2];
    XCTAssertTrue([store getTotalEventCount] == 2, @"2 total events after deleteEventsFromOffset");
}

- (void)testClosedDB{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store closeDB];

    // Verify that these methods all behave with a closed database.
    XCTAssertFalse([store hasPendingEvents], @"no pending if closed");
    [store resetPendingEvents]; // This shouldn't crash. :P
    [store purgePendingEvents]; // This shouldn't crash. :P
}

- (NSString *)databaseFile {
    NSString *databasePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [databasePath stringByAppendingPathComponent:@"keenEvents.sqlite"];
}

@end
