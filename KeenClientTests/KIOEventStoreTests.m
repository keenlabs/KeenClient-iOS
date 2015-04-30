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
    STAssertNotNil(store, @"init is not null");
    NSString *dbPath = [self databaseFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    STAssertTrue([fileManager fileExistsAtPath:dbPath], @"Database file exists.");
}

- (void)testAdd{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    STAssertTrue([store getTotalEventCount] == 1, @"1 total event after add");
    STAssertTrue([store getPendingEventCount] == 0, @"0 pending events after add");
}

- (void)testDelete{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    STAssertTrue([store getTotalEventCount] == 1, @"1 total event after add");
    STAssertTrue([store getPendingEventCount] == 0, @"0 pending events after add");

    // Lets get some events out now with the purpose of deleteting them.
    NSMutableDictionary *events = [store getEventsWithMaxAttempts:3];
    STAssertTrue([store getPendingEventCount] == 1, @"1 pending events after getEvents");

    for (NSString *coll in events) {
        for (NSNumber *eid in [events objectForKey:coll]) {
            [store deleteEvent:eid];
        }
    }

    STAssertTrue([store getTotalEventCount] == 0, @"0 total events after delete");
    STAssertTrue([store getPendingEventCount] == 0, @"0 pending events after delete");
}

- (void)testGetPending{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];

    // Lets get some events out now with the purpose of sending them off.
    NSMutableDictionary *events = [store getEventsWithMaxAttempts:3];

    STAssertTrue([events count] == 1, @"1 collection returned");
    STAssertTrue([[events objectForKey:@"foo"] count] == 2, @"2 events returned");

    STAssertTrue([store getTotalEventCount] == 2, @"2 total event after add");
    STAssertTrue([store getPendingEventCount] == 2, @"2 pending event after add");
    STAssertTrue([store hasPendingEvents], @"has pending events!");

    [store addEvent:[@"I AM NOT AN EVENT BUT A STRING" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    STAssertTrue([store getTotalEventCount] == 3, @"3 total event after non-pending add");
    STAssertTrue([store getPendingEventCount] == 2, @"2 pending event after add");
}

- (void)testCleanupOfPending{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];

    // Lets get some events out now with the purpose of sending them off.
    [store getEventsWithMaxAttempts:3];

    [store purgePendingEvents];
    STAssertTrue([store getTotalEventCount] == 0, @"0 total event after add");
    STAssertFalse([store hasPendingEvents], @"No pending events now!");

    // Again for good measure
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];

    [store getEventsWithMaxAttempts:3];

    [store purgePendingEvents];
    STAssertTrue([store getTotalEventCount] == 0, @"0 total event after add");
    STAssertFalse([store hasPendingEvents], @"No pending events now!");
}

- (void)testResetOfPending{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];

    // Lets get some events out now with the purpose of sending them off.
    [store getEventsWithMaxAttempts:3];
    STAssertTrue([store getTotalEventCount] == 2, @"2 total event after add");
    STAssertTrue([store getPendingEventCount] == 2, @"2 pending event after add");
    STAssertTrue([store hasPendingEvents], @"has pending events!");

    [store resetPendingEvents];
    STAssertTrue([store getTotalEventCount] == 2, @"0 total event after reset");
    STAssertTrue([store getPendingEventCount] == 0, @"2 pending event after reset");
    STAssertFalse([store hasPendingEvents], @"has NO pending events!");

    // Again for good measure
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];

    [store getEventsWithMaxAttempts:3];

    [store resetPendingEvents];
    STAssertTrue([store getTotalEventCount] == 4, @"0 total event after add");
    STAssertFalse([store hasPendingEvents], @"No pending events now!");
}

- (void)testDeleteFromOffset{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
    [store addEvent:[@"I AM AN BUT ANOTHER EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];

    [store deleteEventsFromOffset:@2];
    STAssertTrue([store getTotalEventCount] == 2, @"2 total events after deleteEventsFromOffset");
}

- (void)testClosedDB{
    KIOEventStore *store = [[KIOEventStore alloc] init];
    store.projectId = @"1234";
    [store closeDB];

    // Verify that these methods all behave with a closed database.

    STAssertFalse([store hasPendingEvents], @"no pending if closed");
    [store resetPendingEvents]; // This shouldn't crash. :P
    STAssertFalse([store addEvent:[@"POOP" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"], @"add event should fail if closed");
    STAssertTrue([[store getEventsWithMaxAttempts:3] count] == 0, @"no events if closed");
    STAssertTrue([store getPendingEventCount] == 0, @"no pending if closed");
    STAssertTrue([store getTotalEventCount] == 0, @"no total if closed");
    [store purgePendingEvents]; // This shouldn't crash. :P
}

- (NSString *)databaseFile {
    NSString *databasePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [databasePath stringByAppendingPathComponent:@"keenEvents.sqlite"];
}

@end
