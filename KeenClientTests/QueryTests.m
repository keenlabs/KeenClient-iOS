//
//  QueryTests.m
//  KeenClient
//
//  Created by Brian Baumhover on 5/9/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <OCMock/OCMock.h>

#import "KeenClient.h"
#import "HTTPCodes.h"

#import "KeenClientTestable.h"
#import "KeenTestConstants.h"
#import "KIONetworkTestable.h"

#import "QueryTests.h"

@implementation QueryTests

- (void)testCountQueryFailure {
    XCTestExpectation *queryCompleted =
        [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{} andStatusCode:HTTPCode5XXServerError];

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{}];

    [mock runAsyncQuery:query
        completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
            KCLogInfo(@"error: %@", error);
            KCLogInfo(@"response: %@", response);

            XCTAssertNil(error);

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            XCTAssertEqual([httpResponse statusCode], HTTPCode5XXServerError);

            NSDictionary *responseDictionary =
                [NSJSONSerialization JSONObjectWithData:queryResponseData options:kNilOptions error:&error];

            KCLogInfo(@"response: %@", responseDictionary);

            NSNumber *result = [responseDictionary objectForKey:@"result"];

            XCTAssertNil(result);

            [queryCompleted fulfill];
        }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testCountQuerySuccess {
    XCTestExpectation *queryCompleted =
        [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{ @"result": @10 } andStatusCode:HTTPCode200OK];

    KIOQuery *query =
        [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{
            @"event_collection": @"event_collection"
        }];

    [mock runAsyncQuery:query
        completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
            KCLogInfo(@"error: %@", error);
            KCLogInfo(@"response: %@", response);

            XCTAssertNil(error);

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

            NSDictionary *responseDictionary =
                [NSJSONSerialization JSONObjectWithData:queryResponseData options:kNilOptions error:&error];

            KCLogInfo(@"response: %@", responseDictionary);

            NSNumber *result = [responseDictionary objectForKey:@"result"];

            XCTAssertEqual(result, [NSNumber numberWithInt:10]);

            [queryCompleted fulfill];
        }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testCountQuerySuccessWithGroupByProperty {
    XCTestExpectation *queryCompleted =
        [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{
        @"result": @[@{@"result": @10, @"key": @"value"}]
    }
                                   andStatusCode:HTTPCode200OK];

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count"
                              andPropertiesDictionary:@{
                                  @"event_collection": @"event_collection",
                                  @"group_by": @"key"
                              }];

    [mock runAsyncQuery:query
        completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
            KCLogInfo(@"error: %@", error);
            KCLogInfo(@"response: %@", response);

            XCTAssertNil(error);

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

            NSDictionary *responseDictionary =
                [NSJSONSerialization JSONObjectWithData:queryResponseData options:kNilOptions error:&error];

            KCLogInfo(@"response: %@", responseDictionary);

            NSNumber *result = [[responseDictionary objectForKey:@"result"][0] objectForKey:@"result"];

            XCTAssertEqual(result, [NSNumber numberWithInt:10]);
            [queryCompleted fulfill];
        }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testCountQuerySuccessWithTimeframeAndIntervalProperties {
    XCTestExpectation *queryCompleted =
        [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{
        @"result": @[@{
            @"value": @10,
            @"timeframe": @{@"start": @"2015-06-19T00:00:00.000Z", @"end": @"2015-06-20T00:00:00.000Z"}
        }]
    }
                                   andStatusCode:HTTPCode200OK];

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count"
                              andPropertiesDictionary:@{
                                  @"event_collection": @"event_collection",
                                  @"interval": @"daily",
                                  @"timeframe": @"last_1_days"
                              }];

    [mock runAsyncQuery:query
        completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
            KCLogInfo(@"error: %@", error);
            KCLogInfo(@"response: %@", response);

            XCTAssertNil(error);

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

            NSDictionary *responseDictionary =
                [NSJSONSerialization JSONObjectWithData:queryResponseData options:kNilOptions error:&error];

            KCLogInfo(@"response: %@", responseDictionary);

            NSNumber *result = [[responseDictionary objectForKey:@"result"][0] objectForKey:@"value"];

            XCTAssertEqual(result, [NSNumber numberWithInt:10]);

            [queryCompleted fulfill];
        }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testCountUniqueQueryWithMissingTargetProperty {
    XCTestExpectation *queryCompleted =
        [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{} andStatusCode:HTTPCode400BadRequest];

    KIOQuery *query =
        [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{
            @"event_collection": @"event_collection"
        }];

    [mock runAsyncQuery:query
        completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
            KCLogInfo(@"error: %@", error);
            KCLogInfo(@"response: %@", response);

            XCTAssertNil(error);

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            XCTAssertEqual([httpResponse statusCode], HTTPCode400BadRequest);

            NSDictionary *responseDictionary =
                [NSJSONSerialization JSONObjectWithData:queryResponseData options:kNilOptions error:&error];

            KCLogInfo(@"response: %@", responseDictionary);

            NSNumber *result = [responseDictionary objectForKey:@"result"];

            XCTAssertNil(result);

            [queryCompleted fulfill];
        }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testCountUniqueQuerySuccess {
    XCTestExpectation *queryCompleted =
        [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{ @"result": @10 } andStatusCode:HTTPCode200OK];

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"count"
                              andPropertiesDictionary:@{
                                  @"event_collection": @"event_collection",
                                  @"target_property": @"something"
                              }];

    [mock runAsyncQuery:query
        completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
            KCLogInfo(@"error: %@", error);
            KCLogInfo(@"response: %@", response);

            XCTAssertNil(error);

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

            NSDictionary *responseDictionary =
                [NSJSONSerialization JSONObjectWithData:queryResponseData options:kNilOptions error:&error];

            KCLogInfo(@"response: %@", responseDictionary);

            NSNumber *result = [responseDictionary objectForKey:@"result"];

            XCTAssertEqual(result, [NSNumber numberWithInt:10]);

            [queryCompleted fulfill];
        }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testMultiAnalysisSuccess {
    XCTestExpectation *queryCompleted =
        [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{
        @"result": @{@"query1": @10, @"query2": @1}
    }
                                   andStatusCode:HTTPCode200OK];

    KIOQuery *countQuery =
        [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{
            @"event_collection": @"event_collection"
        }];

    KIOQuery *averageQuery = [[KIOQuery alloc] initWithQuery:@"count_unique"
                                     andPropertiesDictionary:@{
                                         @"event_collection": @"event_collection",
                                         @"target_property": @"something"
                                     }];

    [mock runAsyncMultiAnalysisWithQueries:@[countQuery, averageQuery]
                         completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
                             KCLogInfo(@"error: %@", error);
                             KCLogInfo(@"response: %@", response);

                             XCTAssertNil(error);

                             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                             XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

                             NSDictionary *responseDictionary =
                                 [NSJSONSerialization JSONObjectWithData:queryResponseData
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
    XCTestExpectation *queryCompleted =
        [self expectationWithDescription:@"runAsyncQuery should call completionHandler."];
    id mock = [self createClientWithResponseData:@{
        @"result": @[@10, @5],
        @"steps": @[
            @{@"actor_property": @[@"user.id"], @"event_collection": @"user_signed_up"},
            @{@"actor_property": @[@"user.id"], @"event_collection": @"user_completed_profile"}
        ]
    }
                                   andStatusCode:HTTPCode200OK];

    KIOQuery *query = [[KIOQuery alloc] initWithQuery:@"funnel"
                              andPropertiesDictionary:@{
                                  @"steps": @[
                                      @{@"event_collection": @"user_signed_up", @"actor_property": @"user.id"},
                                      @{@"event_collection": @"user_completed_profile", @"actor_property": @"user.id"}
                                  ]
                              }];

    [mock runAsyncQuery:query
        completionHandler:^(NSData *queryResponseData, NSURLResponse *response, NSError *error) {
            KCLogInfo(@"error: %@", error);
            KCLogInfo(@"response: %@", response);

            XCTAssertNil(error);

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

            NSDictionary *responseDictionary =
                [NSJSONSerialization JSONObjectWithData:queryResponseData options:kNilOptions error:&error];

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

- (void)testSuccessfulQueryAPIResponse {
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
                              andProjectID:kDefaultProjectID
                                  andError:nil];

    // test that there are no entries in the query database
    XCTAssertEqual([KIODBStore.sharedInstance getTotalQueryCountWithProjectID:kDefaultProjectID],
                   (NSUInteger)0,
                   @"There should be no queries after a successful query API call");
}

- (void)testFailedQueryAPIResponse {
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
    KIOQuery *query =
        [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{
            @"event_collection": @"collection"
        }];

    [client.network handleQueryAPIResponse:response
                                   andData:responseData
                                  andQuery:query
                              andProjectID:kDefaultProjectID
                                  andError:nil];

    NSUInteger numberOfQueries = [KIODBStore.sharedInstance getTotalQueryCountWithProjectID:kDefaultProjectID];

    XCTAssertEqual(
        numberOfQueries, (NSUInteger)1, @"There should be 1 query in the database after a failed query API call");

    // test that there are 2 entries in the query database after two failed different query API calls
    KIOQuery *query2 =
        [[KIOQuery alloc] initWithQuery:@"count" andPropertiesDictionary:@{
            @"event_collection": @"collection2"
        }];

    [client.network handleQueryAPIResponse:response
                                   andData:responseData
                                  andQuery:query2
                              andProjectID:kDefaultProjectID
                                  andError:nil];

    numberOfQueries = [KIODBStore.sharedInstance getTotalQueryCountWithProjectID:kDefaultProjectID];
    XCTAssertEqual(
        numberOfQueries, (NSUInteger)2, @"There should be 2 queries in the database after two failed query API calls");

    // test that there is still 2 entries in the query database after the same query fails twice
    [client.network handleQueryAPIResponse:response
                                   andData:responseData
                                  andQuery:query2
                              andProjectID:kDefaultProjectID
                                  andError:nil];

    numberOfQueries = [KIODBStore.sharedInstance getTotalQueryCountWithProjectID:kDefaultProjectID];
    XCTAssertEqual(numberOfQueries,
                   (NSUInteger)2,
                   @"There should still be 2 queries in the database after two of the same failed query API call");
}

@end
