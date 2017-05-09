//
//  KIODBStoreTests.m
//  KeenClient
//
//  Created by Cory Watson on 3/26/14.
//  Copyright (c) 2014 Keen Labs. All rights reserved.
//

#import "KIODBStore.h"

#import "KeenTestConstants.h"
#import "KeenTestUtils.h"
#import "KeenTestCaseBase.h"
#import "KIODBStoreTests.h"
#import "KIODBStorePrivate.h"
#import "KIODBStoreTestable.h"
#import "KIOQuery.h"
#import "TestDatabaseRequirement.h"

@interface KIODBStoreTests ()

@property NSString *projectID;

- (NSString *)databaseFile;

@end

@implementation KIODBStoreTests

@synthesize projectID;

- (void)setUp {
    [super setUp];

    projectID = @"pid";
}

- (void)tearDown {
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
    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"collection"}];

    [store addQuery:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID];

    XCTAssertTrue([store getTotalQueryCountWithProjectID:projectID] == 1, @"1 total event after add");
}

- (void)testQueryGet {
    KIODBStore *store = [[KIODBStore alloc] init];
    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"collection"}];
    KIOQuery *query2 = [[KIOQuery alloc] initWithQuery:@"count_unique" andPropertiesDictionary:@{@"event_collection": @"collection2"}];

    [store addQuery:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID];
    [store addQuery:[query2 convertQueryToData] queryType:query2.queryType collection:[query2.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID];

    XCTAssertTrue([store getTotalQueryCountWithProjectID:projectID] == 2, @"2 total event after add");

    NSMutableDictionary *returnedQuery = [store getQuery:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID];

    XCTAssertNotNil(returnedQuery, @"returned query is not nil");
    XCTAssertEqualObjects([query.propertiesDictionary objectForKey:@"event_collection"], [returnedQuery objectForKey:@"event_collection"], @"event collection is the same");
    XCTAssertEqualObjects([query convertQueryToData], [returnedQuery objectForKey:@"queryData"], @"query data is the same");
    XCTAssertEqualObjects(query.queryType, [returnedQuery objectForKey:@"queryType"], @"query type is the same");
    XCTAssertEqual([[returnedQuery objectForKey:@"attempts"] intValue], 0, @"attempts is 0");

    NSMutableDictionary *returnedQuery2 = [store getQuery:[query2 convertQueryToData] queryType:query2.queryType collection:[query2.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID];

    XCTAssertNotNil(returnedQuery2, @"returned query is not nil");
    XCTAssertEqualObjects([query2.propertiesDictionary objectForKey:@"event_collection"], [returnedQuery2 objectForKey:@"event_collection"], @"event collection is the same");
    XCTAssertEqualObjects([query2 convertQueryToData], [returnedQuery2 objectForKey:@"queryData"], @"query data is the same");
    XCTAssertEqual([[returnedQuery2 objectForKey:@"attempts"] intValue], 0, @"attempts is 0");
}

- (void) testQueryUpdate {
    KIODBStore *store = [[KIODBStore alloc] init];
    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"collection"}];

    // first add and retrieve query, make sure attempts is 0
    [store addQuery:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID];

    NSMutableDictionary *returnedQuery = [store getQuery:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID];

    XCTAssertEqual([[returnedQuery objectForKey:@"attempts"] intValue], 0, @"attempts is 0");

    // update query attempts
    BOOL wasQueryUpdated = [store incrementQueryAttempts:[returnedQuery objectForKey:@"queryID"]];

    XCTAssertTrue(wasQueryUpdated);

    // grab updated query and check attempt number
    NSMutableDictionary *returnUpdateQuery = [store getQuery:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID];

    XCTAssertNotNil(returnUpdateQuery, @"returned query is not nil");
    XCTAssertEqualObjects([query.propertiesDictionary objectForKey:@"event_collection"], [returnUpdateQuery objectForKey:@"event_collection"], @"event collection is the same");
    XCTAssertEqualObjects([query convertQueryToData], [returnUpdateQuery objectForKey:@"queryData"], @"query data is the same");
    XCTAssertEqual([[returnUpdateQuery objectForKey:@"attempts"] intValue], 1, @"attempts is 1");
}

- (void) testQueryDeleteAll {
    KIODBStore *store = [[KIODBStore alloc] init];
    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"collection"}];

    [store addQuery:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID];

    XCTAssertTrue([store getTotalQueryCountWithProjectID:projectID] == 1, @"1 total query after add");

    [store deleteAllQueries];

    XCTAssertTrue([store getTotalQueryCountWithProjectID:projectID] == 0, @"0 total query after deleteAllQueries");
}

- (void) testHasQueryWithMaxAttempts {
    KIODBStore *store = [[KIODBStore alloc] init];
    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"collection"}];

    [store addQuery:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID];

    XCTAssertTrue([store getTotalQueryCountWithProjectID:projectID] == 1, @"1 total query after add");

    // test that query succeds with maxAttempts set to 0
    int maxAttempts = 0;

    BOOL hasQueryWithMaxAttempts = [store hasQueryWithMaxAttempts:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID maxAttempts:maxAttempts queryTTL:1];

    XCTAssertTrue(hasQueryWithMaxAttempts, @"query found with attempts equal to or over 0");

    // test that query fails with maxAttempts set to 1
    maxAttempts = 1;

    hasQueryWithMaxAttempts = [store hasQueryWithMaxAttempts:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID maxAttempts:maxAttempts queryTTL:1];

    XCTAssertFalse(hasQueryWithMaxAttempts, @"query not found with attempts equal to or over 1");

    // test that query succeds after query attempts value is incremented
    NSMutableDictionary *returnedQuery = [store getQuery:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID];

    [store incrementQueryAttempts:[returnedQuery objectForKey:@"queryID"]];

    hasQueryWithMaxAttempts = [store hasQueryWithMaxAttempts:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID maxAttempts:maxAttempts queryTTL:1];

    XCTAssertTrue(hasQueryWithMaxAttempts, @"query found with attempts equal to or over 1");
}

- (void)testDeleteQueriesOlderThanXSeconds {
    KIODBStore *store = [[KIODBStore alloc] init];
    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"collection"}];

    [store addQuery:[query convertQueryToData] queryType:query.queryType collection:[query.propertiesDictionary objectForKey:@"event_collection"] projectID:projectID];

    int totalQueries = [store getTotalQueryCountWithProjectID:projectID];
    XCTAssertTrue(totalQueries == 1, @"1 total query after add");

    // wait for 2 seconds
    [NSThread sleepForTimeInterval:2.0];

    // try to delete queries older than 10 seconds
    [store deleteQueriesOlderThan:[NSNumber numberWithInt:10]];

    totalQueries = [store getTotalQueryCountWithProjectID:projectID];
    XCTAssertTrue(totalQueries == 1, @"1 total query after trying to delete queries older than 10 seconds");

    // try to delete queries older than 1 second
    [store deleteQueriesOlderThan:[NSNumber numberWithInt:1]];

    totalQueries = [store getTotalQueryCountWithProjectID:projectID];
    XCTAssertTrue(totalQueries == 0, @"0 total query after trying to delete queries older than 1 seconds");
}

- (void)testRecoverFromCorruptDb {
    // Copy a canned corrupt db to the db path
    [self setUpCorruptDb];

    KIODBStore *store = [[KIODBStore alloc] init];
    XCTAssertNotNil(store, @"init is not null");
    NSString *dbPath = [self databaseFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    XCTAssertTrue([fileManager fileExistsAtPath:dbPath], @"Database file exists.");

    NSString* event = @"{ \"event\": \"something\" }";

    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 0, @"0 pending events after init");
    XCTAssertTrue([store addEvent:[event dataUsingEncoding:NSUTF8StringEncoding] collection:@"collection" projectID:projectID]);
    XCTAssertTrue([store getTotalEventCountWithProjectID:projectID] == 1, @"1 pending events after add");

    NSMutableDictionary* events = [store getEventsWithMaxAttempts:3 andProjectID:projectID];

    XCTAssertEqual(events.count, 1, @"Should only be one event in the store");
    for (NSString *coll in events) {
        for (NSNumber *eid in [events objectForKey:coll]) {
            [store deleteEvent:eid];
        }
    }

    XCTAssertTrue([store getPendingEventCountWithProjectID:projectID] == 0, @"0 pending events after init");
}

# pragma mark - Helper Methods

- (NSString *)databaseFile {
    return [KIODBStore getSqliteFullFileName];
}

- (void) setUpCorruptDb {
    NSString *corruptDbPath = [[[NSBundle bundleForClass:self.class] resourcePath] stringByAppendingPathComponent:@"corrupt.sqlite"];
    [[NSFileManager defaultManager] copyItemAtPath:corruptDbPath toPath:self.databaseFile error:nil];
}

@end
