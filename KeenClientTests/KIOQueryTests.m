//
//  KIOQueryTests.m
//  KeenClient
//
//  Created by Heitor Sergent on 4/21/15.
//  Copyright (c) 2015 Keen Labs. All rights reserved.
//

#import "KIOQueryTests.h"
#import "KIOQuery.h"
#import "KeenClient.h"

@interface KIOQueryTests ()

@end

@implementation KIOQueryTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Tear-down code here.
    [super tearDown];
}

- (void)testInit {
    KIOQuery *query = [[KIOQuery alloc] init];
    
    XCTAssertNotNil(query, @"init is not null");
}

- (void)testInitWithQueryType {
    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"test"}];
    XCTAssertTrue([query.queryType isEqual:@"count"], @"count");
    XCTAssertTrue([[query.propertiesDictionary valueForKey:@"event_collection"] isEqual:@"test"], @"test");
}

- (void)testGetQueryData {
    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{@"event_collection": @"awesome code"}];
    
    NSData *data = [query convertQueryToData];
    
    KCLog(@"Error when writing event to file: %@", data);
    
    XCTAssertNotNil(data, @"data is not null");
}

//- (void)testAdd{
//    KIOEventStore *store = [[KIOEventStore alloc] init];
//    store.projectId = @"1234";
//    [store addEvent:[@"I AM AN EVENT" dataUsingEncoding:NSUTF8StringEncoding] collection: @"foo"];
//    XCTAssertTrue([store getTotalEventCount] == 1, @"1 total event after add");
//    XCTAssertTrue([store getPendingEventCount] == 0, @"0 pending events after add");
//}

@end
