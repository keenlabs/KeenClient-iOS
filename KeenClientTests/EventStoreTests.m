//
//  EventStoreTests.m
//  KeenClient
//
//  Created by Cory Watson on 3/26/14.
//  Copyright (c) 2014 Keen Labs. All rights reserved.
//

#import "EventStore.h"
#import "EventStoreTests.h"

@interface EventStoreTests ()

- (NSString *)databaseFile;

@end

@implementation EventStoreTests

- (void)setUp {
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
    EventStore *store = [[EventStore alloc] init];
    STAssertNotNil(store, @"init is not null");
    NSString *dbPath = [self databaseFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    STAssertTrue([fileManager fileExistsAtPath:dbPath], @"Database file exists.");
}

- (void)testAdd{
    EventStore *store = [[EventStore alloc] init];
    [store addEvent:@"I AM AN EVENT"];
    STAssertEquals([store getTotalEventCount], 1, @"1 total event after add");
    STAssertEquals([store getPendingEventCount], 0, @"0 pending events after add");
}

- (void)testGetPending{
    EventStore *store = [[EventStore alloc] init];
    [store addEvent:@"I AM AN EVENT"];
    [store addEvent:@"I AM AN EVENT ALSO"];

    // Lets get some events out now with the purpose of sending them off.
    NSMutableArray *events = [store getEvents];

    STAssertTrue([events count] == 2, @"2 event returned");

    STAssertTrue([store getTotalEventCount] == 2, @"2 total event after add");
    STAssertTrue([store getPendingEventCount] == 2, @"2 pending event after add");
    STAssertTrue([store hasPendingEvents], @"has pending events!");

    [store addEvent:@"I AM NOT AN EVENT BUT A STRING"];
    STAssertTrue([store getTotalEventCount] == 3, @"3 total event after non-pending add");
    STAssertTrue([store getPendingEventCount] == 2, @"2 pending event after add");
}

- (void)testCleanupOfPending{
    EventStore *store = [[EventStore alloc] init];
    [store addEvent:@"I AM AN EVENT"];
    [store addEvent:@"I AM AN EVENT ALSO"];

    // Lets get some events out now with the purpose of sending them off.
    NSMutableArray *events = [store getEvents];

    [store purgePendingEvents];
    STAssertTrue([store getTotalEventCount] == 0, @"0 total event after add");
    STAssertFalse([store hasPendingEvents], @"No events now!");

    // Again for good measure
    [store addEvent:@"I AM AN EVENT"];
    [store addEvent:@"I AM AN EVENT ALSO"];

    NSMutableArray *moreEvents = [store getEvents];

    [store purgePendingEvents];
    STAssertTrue([store getTotalEventCount] == 0, @"0 total event after add");
    STAssertFalse([store hasPendingEvents], @"No events now!");
}

- (NSString *)databaseFile {
    NSString *databasePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [databasePath stringByAppendingPathComponent:@"keenEvents.sqlite"];
}



@end
