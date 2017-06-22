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

@interface KIODBStoreTests ()

@property NSString *projectID;

- (NSString *)databaseFile;

@property KIODBStore *store;

@end

@implementation KIODBStoreTests

@synthesize projectID;

- (void)setUp {
    [super setUp];

    projectID = @"pid";
}

- (void)tearDown {
    if (nil != self.store) {
        [self.store drainQueue];
        [self.store closeDB];
        self.store = nil;
    }

    [super tearDown];
}

- (void)testInit {
    self.store = [[KIODBStore alloc] init];
    XCTAssertNotNil(self.store, @"init is not null");
    NSString *dbPath = [self databaseFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    XCTAssertTrue([fileManager fileExistsAtPath:dbPath], @"Database file exists.");
}

- (void)testClosedDB {
    self.store = [[KIODBStore alloc] init];
    [self.store closeDB];

    // Verify that these methods all behave with a closed database.
    XCTAssertFalse([self.store hasPendingEventsWithProjectID:projectID], @"no pending if closed");
    [self.store resetPendingEventsWithProjectID:projectID]; // This shouldn't crash. :P
    [self.store purgePendingEventsWithProjectID:projectID]; // This shouldn't crash. :P
}

#pragma mark - Event Methods

- (void)testEventAdd {
    self.store = [[KIODBStore alloc] init];
    [self.store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 1, @"1 total event after add");
    XCTAssertTrue([self.store getPendingEventCountWithProjectID:projectID] == 0, @"0 pending events after add");
}

- (void)testEventDelete {
    self.store = [[KIODBStore alloc] init];
    [self.store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 1, @"1 total event after add");
    XCTAssertTrue([self.store getPendingEventCountWithProjectID:projectID] == 0, @"0 pending events after add");

    // Lets get some events out now with the purpose of deleteting them.
    NSMutableDictionary *events = [self.store getEventsWithMaxAttempts:3 andProjectID:projectID];
    XCTAssertTrue([self.store getPendingEventCountWithProjectID:projectID] == 1, @"1 pending events after getEvents");

    for (NSString *coll in events) {
        for (NSNumber *eid in [events objectForKey:coll]) {
            [self.store deleteEvent:eid];
        }
    }

    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 0, @"0 total events after delete");
    XCTAssertTrue([self.store getPendingEventCountWithProjectID:projectID] == 0, @"0 pending events after delete");
}

- (void)testEventGetPending {
    self.store = [[KIODBStore alloc] init];
    [self.store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [self.store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding]
         collection:@"foo"
          projectID:projectID];

    // Lets get some events out now with the purpose of sending them off.
    NSMutableDictionary *events = [self.store getEventsWithMaxAttempts:3 andProjectID:projectID];

    XCTAssertTrue([events count] == 1, @"1 collection returned");
    XCTAssertTrue([[events objectForKey:@"foo"] count] == 2, @"2 events returned");

    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 2, @"2 total event after add");
    XCTAssertTrue([self.store getPendingEventCountWithProjectID:projectID] == 2, @"2 pending event after add");
    XCTAssertTrue([self.store hasPendingEventsWithProjectID:projectID], @"has pending events!");

    [self.store addEvent:[@"I AM NOT AN EVENT BUT A STRING" dataUsingEncoding:NSUTF8StringEncoding]
         collection:@"foo"
          projectID:projectID];
    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 3, @"3 total event after non-pending add");
    XCTAssertTrue([self.store getPendingEventCountWithProjectID:projectID] == 2, @"2 pending event after add");
}

- (void)testEventCleanupOfPending {
    self.store = [[KIODBStore alloc] init];
    [self.store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [self.store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding]
         collection:@"foo"
          projectID:projectID];

    // Lets get some events out now with the purpose of sending them off.
    [self.store getEventsWithMaxAttempts:3 andProjectID:projectID];

    [self.store purgePendingEventsWithProjectID:projectID];
    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 0, @"0 total event after add");
    XCTAssertFalse([self.store hasPendingEventsWithProjectID:projectID], @"No pending events now!");

    // Again for good measure
    [self.store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [self.store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding]
         collection:@"foo"
          projectID:projectID];

    [self.store getEventsWithMaxAttempts:3 andProjectID:projectID];

    [self.store purgePendingEventsWithProjectID:projectID];
    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 0, @"0 total event after add");
    XCTAssertFalse([self.store hasPendingEventsWithProjectID:projectID], @"No pending events now!");
}

- (void)testEventResetOfPending {
    self.store = [[KIODBStore alloc] init];
    [self.store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [self.store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding]
         collection:@"foo"
          projectID:projectID];

    // Lets get some events out now with the purpose of sending them off.
    [self.store getEventsWithMaxAttempts:3 andProjectID:projectID];
    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 2, @"2 total event after add");
    XCTAssertTrue([self.store getPendingEventCountWithProjectID:projectID] == 2, @"2 pending event after add");
    XCTAssertTrue([self.store hasPendingEventsWithProjectID:projectID], @"has pending events!");

    [self.store resetPendingEventsWithProjectID:projectID];
    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 2, @"0 total event after reset");
    XCTAssertTrue([self.store getPendingEventCountWithProjectID:projectID] == 0, @"2 pending event after reset");
    XCTAssertFalse([self.store hasPendingEventsWithProjectID:projectID], @"has NO pending events!");

    // Again for good measure
    [self.store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [self.store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding]
         collection:@"foo"
          projectID:projectID];

    [self.store getEventsWithMaxAttempts:3 andProjectID:projectID];

    [self.store resetPendingEventsWithProjectID:projectID];
    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 4, @"0 total event after add");
    XCTAssertFalse([self.store hasPendingEventsWithProjectID:projectID], @"No pending events now!");
}

- (void)testEventDeleteFromOffset {
    self.store = [[KIODBStore alloc] init];
    [self.store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection:@"foo" projectID:projectID];
    [self.store addEvent:[@"I AM AN EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding]
         collection:@"foo"
          projectID:projectID];
    [self.store addEvent:[@"I AM AN BUT ANOTHER EVENT ALSO" dataUsingEncoding:NSUTF8StringEncoding]
         collection:@"foo"
          projectID:projectID];

    [self.store deleteEventsFromOffset:@2];
    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 2,
                  @"2 total events after deleteEventsFromOffset");
}

#pragma mark - Query Methods

- (void)testQueryAdd {
    self.store = [[KIODBStore alloc] init];
    KIOQuery *query =
        [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{
            @"event_collection": @"collection"
        }];

    [self.store addQuery:[query convertQueryToData]
          queryType:query.queryType
         collection:[query.propertiesDictionary objectForKey:@"event_collection"]
          projectID:projectID];

    XCTAssertTrue([self.store getTotalQueryCountWithProjectID:projectID] == 1, @"1 total event after add");
}

- (void)testQueryGet {
    self.store = [[KIODBStore alloc] init];
    KIOQuery *query =
        [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{
            @"event_collection": @"collection"
        }];
    KIOQuery *query2 = [[KIOQuery alloc] initWithQuery:@"count_unique"
                               andPropertiesDictionary:@{
                                   @"event_collection": @"collection2"
                               }];

    [self.store addQuery:[query convertQueryToData]
          queryType:query.queryType
         collection:[query.propertiesDictionary objectForKey:@"event_collection"]
          projectID:projectID];
    [self.store addQuery:[query2 convertQueryToData]
          queryType:query2.queryType
         collection:[query2.propertiesDictionary objectForKey:@"event_collection"]
          projectID:projectID];

    XCTAssertTrue([self.store getTotalQueryCountWithProjectID:projectID] == 2, @"2 total event after add");

    NSMutableDictionary *returnedQuery = [self.store getQuery:[query convertQueryToData]
                                               queryType:query.queryType
                                              collection:[query.propertiesDictionary objectForKey:@"event_collection"]
                                               projectID:projectID];

    XCTAssertNotNil(returnedQuery, @"returned query is not nil");
    XCTAssertEqualObjects([query.propertiesDictionary objectForKey:@"event_collection"],
                          [returnedQuery objectForKey:@"event_collection"],
                          @"event collection is the same");
    XCTAssertEqualObjects(
        [query convertQueryToData], [returnedQuery objectForKey:@"queryData"], @"query data is the same");
    XCTAssertEqualObjects(query.queryType, [returnedQuery objectForKey:@"queryType"], @"query type is the same");
    XCTAssertEqual([[returnedQuery objectForKey:@"attempts"] intValue], 0, @"attempts is 0");

    NSMutableDictionary *returnedQuery2 = [self.store getQuery:[query2 convertQueryToData]
                                                queryType:query2.queryType
                                               collection:[query2.propertiesDictionary objectForKey:@"event_collection"]
                                                projectID:projectID];

    XCTAssertNotNil(returnedQuery2, @"returned query is not nil");
    XCTAssertEqualObjects([query2.propertiesDictionary objectForKey:@"event_collection"],
                          [returnedQuery2 objectForKey:@"event_collection"],
                          @"event collection is the same");
    XCTAssertEqualObjects(
        [query2 convertQueryToData], [returnedQuery2 objectForKey:@"queryData"], @"query data is the same");
    XCTAssertEqual([[returnedQuery2 objectForKey:@"attempts"] intValue], 0, @"attempts is 0");
}

- (void)testQueryUpdate {
    self.store = [[KIODBStore alloc] init];
    KIOQuery *query =
        [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{
            @"event_collection": @"collection"
        }];

    // first add and retrieve query, make sure attempts is 0
    [self.store addQuery:[query convertQueryToData]
          queryType:query.queryType
         collection:[query.propertiesDictionary objectForKey:@"event_collection"]
          projectID:projectID];

    NSMutableDictionary *returnedQuery = [self.store getQuery:[query convertQueryToData]
                                               queryType:query.queryType
                                              collection:[query.propertiesDictionary objectForKey:@"event_collection"]
                                               projectID:projectID];

    XCTAssertEqual([[returnedQuery objectForKey:@"attempts"] intValue], 0, @"attempts is 0");

    // update query attempts
    BOOL wasQueryUpdated = [self.store incrementQueryAttempts:[returnedQuery objectForKey:@"queryID"]];

    XCTAssertTrue(wasQueryUpdated);

    // grab updated query and check attempt number
    NSMutableDictionary *returnUpdateQuery =
        [self.store getQuery:[query convertQueryToData]
              queryType:query.queryType
             collection:[query.propertiesDictionary objectForKey:@"event_collection"]
              projectID:projectID];

    XCTAssertNotNil(returnUpdateQuery, @"returned query is not nil");
    XCTAssertEqualObjects([query.propertiesDictionary objectForKey:@"event_collection"],
                          [returnUpdateQuery objectForKey:@"event_collection"],
                          @"event collection is the same");
    XCTAssertEqualObjects(
        [query convertQueryToData], [returnUpdateQuery objectForKey:@"queryData"], @"query data is the same");
    XCTAssertEqual([[returnUpdateQuery objectForKey:@"attempts"] intValue], 1, @"attempts is 1");
}

- (void)testQueryDeleteAll {
    self.store = [[KIODBStore alloc] init];
    KIOQuery *query =
        [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{
            @"event_collection": @"collection"
        }];

    [self.store addQuery:[query convertQueryToData]
          queryType:query.queryType
         collection:[query.propertiesDictionary objectForKey:@"event_collection"]
          projectID:projectID];

    XCTAssertTrue([self.store getTotalQueryCountWithProjectID:projectID] == 1, @"1 total query after add");

    [self.store deleteAllQueries];

    XCTAssertTrue([self.store getTotalQueryCountWithProjectID:projectID] == 0, @"0 total query after deleteAllQueries");
}

- (void)testHasQueryWithMaxAttempts {
    self.store = [[KIODBStore alloc] init];
    KIOQuery *query =
        [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{
            @"event_collection": @"collection"
        }];

    [self.store addQuery:[query convertQueryToData]
          queryType:query.queryType
         collection:[query.propertiesDictionary objectForKey:@"event_collection"]
          projectID:projectID];

    XCTAssertTrue([self.store getTotalQueryCountWithProjectID:projectID] == 1, @"1 total query after add");

    // test that query succeds with maxAttempts set to 0
    int maxAttempts = 0;

    BOOL hasQueryWithMaxAttempts =
        [self.store hasQueryWithMaxAttempts:[query convertQueryToData]
                             queryType:query.queryType
                            collection:[query.propertiesDictionary objectForKey:@"event_collection"]
                             projectID:projectID
                           maxAttempts:maxAttempts
                              queryTTL:1];

    XCTAssertTrue(hasQueryWithMaxAttempts, @"query found with attempts equal to or over 0");

    // test that query fails with maxAttempts set to 1
    maxAttempts = 1;

    hasQueryWithMaxAttempts =
        [self.store hasQueryWithMaxAttempts:[query convertQueryToData]
                             queryType:query.queryType
                            collection:[query.propertiesDictionary objectForKey:@"event_collection"]
                             projectID:projectID
                           maxAttempts:maxAttempts
                              queryTTL:1];

    XCTAssertFalse(hasQueryWithMaxAttempts, @"query not found with attempts equal to or over 1");

    // test that query succeds after query attempts value is incremented
    NSMutableDictionary *returnedQuery = [self.store getQuery:[query convertQueryToData]
                                               queryType:query.queryType
                                              collection:[query.propertiesDictionary objectForKey:@"event_collection"]
                                               projectID:projectID];

    [self.store incrementQueryAttempts:[returnedQuery objectForKey:@"queryID"]];

    hasQueryWithMaxAttempts =
        [self.store hasQueryWithMaxAttempts:[query convertQueryToData]
                             queryType:query.queryType
                            collection:[query.propertiesDictionary objectForKey:@"event_collection"]
                             projectID:projectID
                           maxAttempts:maxAttempts
                              queryTTL:1];

    XCTAssertTrue(hasQueryWithMaxAttempts, @"query found with attempts equal to or over 1");
}

- (void)testDeleteQueriesOlderThanXSeconds {
    self.store = [[KIODBStore alloc] init];
    KIOQuery *query =
        [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{
            @"event_collection": @"collection"
        }];

    [self.store addQuery:[query convertQueryToData]
          queryType:query.queryType
         collection:[query.propertiesDictionary objectForKey:@"event_collection"]
          projectID:projectID];

    int totalQueries = [self.store getTotalQueryCountWithProjectID:projectID];
    XCTAssertTrue(totalQueries == 1, @"1 total query after add");

    // wait for 2 seconds
    [NSThread sleepForTimeInterval:2.0];

    // try to delete queries older than 10 seconds
    [self.store deleteQueriesOlderThan:[NSNumber numberWithInt:10]];

    totalQueries = [self.store getTotalQueryCountWithProjectID:projectID];
    XCTAssertTrue(totalQueries == 1, @"1 total query after trying to delete queries older than 10 seconds");

    // try to delete queries older than 1 second
    [self.store deleteQueriesOlderThan:[NSNumber numberWithInt:1]];

    totalQueries = [self.store getTotalQueryCountWithProjectID:projectID];
    XCTAssertTrue(totalQueries == 0, @"0 total query after trying to delete queries older than 1 seconds");
}

- (void)testRecoverFromCorruptDb {
    // Copy a canned corrupt db to the db path
    [self setUpCorruptDb];

    self.store = [[KIODBStore alloc] init];
    XCTAssertNotNil(self.store, @"init is not null");
    NSString *dbPath = [self databaseFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    XCTAssertTrue([fileManager fileExistsAtPath:dbPath], @"Database file exists.");

    NSString *event = @"{ \"event\": \"something\" }";

    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 0, @"0 pending events after init");
    XCTAssertTrue(
        [self.store addEvent:[event dataUsingEncoding:NSUTF8StringEncoding] collection:@"collection" projectID:projectID]);
    XCTAssertTrue([self.store getTotalEventCountWithProjectID:projectID] == 1, @"1 pending events after add");

    NSMutableDictionary *events = [self.store getEventsWithMaxAttempts:3 andProjectID:projectID];

    XCTAssertEqual(events.count, 1, @"Should only be one event in the store");
    for (NSString *coll in events) {
        for (NSNumber *eid in [events objectForKey:coll]) {
            [self.store deleteEvent:eid];
        }
    }

    XCTAssertTrue([self.store getPendingEventCountWithProjectID:projectID] == 0, @"0 pending events after init");
}

#pragma mark - Helper Methods

- (NSString *)databaseFile {
    return [KIODBStore getSqliteFullFileName];
}

- (void)setUpCorruptDb {
    NSString *corruptDbPath =
        [[[NSBundle bundleForClass:self.class] resourcePath] stringByAppendingPathComponent:@"corrupt.sqlite"];
    [[NSFileManager defaultManager] copyItemAtPath:corruptDbPath toPath:self.databaseFile error:nil];
}

@end
