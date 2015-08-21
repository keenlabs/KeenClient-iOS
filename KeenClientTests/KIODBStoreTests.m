//
//  KIOEventStoreTests.m
//  KeenClient
//
//  Created by Cory Watson on 3/26/14.
//  Copyright (c) 2014 Keen Labs. All rights reserved.
//

#import "KIODBStore.h"
#import "KIODBStoreTests.h"
#import "KIOEventStore_PrivateMethods.h"

@interface KIODBStoreTests ()

@property NSString *projectID;

- (NSString *)databaseFile;

@end

@implementation KIODBStoreTests

@synthesize projectID;

- (void)setUp {
    // Clean up, just in case.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager removeItemAtPath:[self databaseFile] error:NULL] == YES) {
        NSLog(@"Removed database file.");
    } else {
        NSLog(@"Failed to remove database file.");
    }
    
    projectID = @"pid";
    
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

- (void)testInit {
    KIODBStore *store = [[KIODBStore alloc] init];
    XCTAssertNotNil(store, @"init is not null");
    NSString *dbPath = [self databaseFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    XCTAssertTrue([fileManager fileExistsAtPath:dbPath], @"Database file exists.");
}

- (void)testClosedDB {
    KIODBStore *store = [[KIODBStore alloc] init];
    [store closeDB];
    
    // Verify that these methods all behave with a closed database.
    XCTAssertFalse([store hasPendingEventsWithProjectID:projectID], @"no pending if closed");
    [store resetPendingEventsWithProjectID:projectID]; // This shouldn't crash. :P
    [store purgePendingEventsWithProjectID:projectID]; // This shouldn't crash. :P
}

# pragma mark - Event Methods

- (void)testEventAdd {
    KIODBStore *store = [[KIODBStore alloc] init];
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 1, @"1 total event after add");
    XCTAssertTrue([store getPendingEventCountWithProjectID:projectID] == 0, @"0 pending events after add");
}

- (void)testEventDelete {
    KIODBStore *store = [[KIODBStore alloc] init];
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 1, @"1 total event after add");
    XCTAssertTrue([store getPendingEventCountWithProjectID:projectID] == 0, @"0 pending events after add");

    // Lets get some events out now with the purpose of deleteting them.
    NSMutableDictionary *events = [store getEventsWithMaxAttempts:3 andProjectID:projectID];
    XCTAssertTrue([store getPendingEventCountWithProjectID:projectID] == 1, @"1 pending events after getEvents");

    for (NSString *coll in events) {
        for (NSNumber *eid in [events objectForKey:coll]) {
            [store deleteEvent:eid];
        }
    }

    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 0, @"0 total events after delete");
    XCTAssertTrue([store getPendingEventCountWithProjectID:projectID] == 0, @"0 pending events after delete");
}

- (void)testEventGetPending {
    KIODBStore *store = [[KIODBStore alloc] init];
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];

    // Lets get some events out now with the purpose of sending them off.
    NSMutableDictionary *events = [store getEventsWithMaxAttempts:3 andProjectID:projectID];

    XCTAssertTrue([events count] == 1, @"1 collection returned");
    XCTAssertTrue([[events objectForKey:@"foo"] count] == 2, @"2 events returned");

    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 2, @"2 total event after add");
    XCTAssertTrue([store getPendingEventCountWithProjectID:projectID] == 2, @"2 pending event after add");
    XCTAssertTrue([store hasPendingEventsWithProjectID:projectID], @"has pending events!");

    [store addEvent:[@"I AM NOT AN EVENT BUT A STRING" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo" projectID:projectID];
    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 3, @"3 total event after non-pending add");
    XCTAssertTrue([store getPendingEventCountWithProjectID:projectID] == 2, @"2 pending event after add");
}

- (void)testEventCleanupOfPending {
    KIODBStore *store = [[KIODBStore alloc] init];
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];

    // Lets get some events out now with the purpose of sending them off.
    [store getEventsWithMaxAttempts:3 andProjectID:projectID];

    [store purgePendingEventsWithProjectID:projectID];
    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 0, @"0 total event after add");
    XCTAssertFalse([store hasPendingEventsWithProjectID:projectID], @"No pending events now!");

    // Again for good measure
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];

    [store getEventsWithMaxAttempts:3 andProjectID:projectID];

    [store purgePendingEventsWithProjectID:projectID];
    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 0, @"0 total event after add");
    XCTAssertFalse([store hasPendingEventsWithProjectID:projectID], @"No pending events now!");
}

- (void)testEventResetOfPending {
    KIODBStore *store = [[KIODBStore alloc] init];
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];

    // Lets get some events out now with the purpose of sending them off.
    [store getEventsWithMaxAttempts:3 andProjectID:projectID];
    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 2, @"2 total event after add");
    XCTAssertTrue([store getPendingEventCountWithProjectID:projectID] == 2, @"2 pending event after add");
    XCTAssertTrue([store hasPendingEventsWithProjectID:projectID], @"has pending events!");

    [store resetPendingEventsWithProjectID:projectID];
    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 2, @"0 total event after reset");
    XCTAssertTrue([store getPendingEventCountWithProjectID:projectID] == 0, @"2 pending event after reset");
    XCTAssertFalse([store hasPendingEventsWithProjectID:projectID], @"has NO pending events!");

    // Again for good measure
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];

    [store getEventsWithMaxAttempts:3 andProjectID:projectID];

    [store resetPendingEventsWithProjectID:projectID];
    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 4, @"0 total event after add");
    XCTAssertFalse([store hasPendingEventsWithProjectID:projectID], @"No pending events now!");
}

- (void)testEventDeleteFromOffset {
    KIODBStore *store = [[KIODBStore alloc] init];
    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [store addEvent:[@"I AM AN BUT ANOTHER EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];

    [store deleteEventsFromOffset:@2];
    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 2, @"2 total events after deleteEventsFromOffset");
}

# pragma mark - Query Methods

- (void)testQueryAdd {
    KIODBStore *store = [[KIODBStore alloc] init];
    [store addQuery:[@"I AM A QUERY" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    XCTAssertTrue([store getTotalQueryCountWithProjectID:projectID] == 1, @"1 total event after add");
}



# pragma mark - Helper Methods

- (NSString *)databaseFile {
    NSString *databasePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [databasePath stringByAppendingPathComponent:@"keenEvents.sqlite"];
}

@end
