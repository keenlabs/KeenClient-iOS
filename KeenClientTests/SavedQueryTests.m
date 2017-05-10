//
//  SavedQueryTests.m
//  KeenClient
//
//  Created by Brian Baumhover on 5/10/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "HTTPCodes.h"
#import "KeenClient.h"

#import "KeenTestConstants.h"

#import "SavedQueryTests.h"

@implementation SavedQueryTests

- (NSDictionary *)urlsForSavedQuery:(NSString *)queryName withProjectID:(NSString *)projectID {
    // Create strings for the "urls" key of a saved query response
    return @{
        @"cached_query_url" : [NSString stringWithFormat:@"/3.0/projects/%@/queries/saved/%@", projectID, queryName],
        @"cached_query_results_url" :
            [NSString stringWithFormat:@"/3.0/projects/%@/queries/saved/%@/result", projectID, queryName]
    };
}

- (void)makeAndValidateSavedQueryRequest:(NSString *)queryName
                  withResponseDictionary:(NSDictionary *)responseDictionary
                      withExpectedResult:(id)expectedResult {
    XCTestExpectation *queryCompleted =
        [self expectationWithDescription:@"runAsyncSavedAnalysis should call completionHandler."];

    // Create a KeenClient instance with a canned HTTP response and a parameter
    // validator that will check that the request URL is as expected
    id mock = [self createClientWithResponseData:responseDictionary
                                   andStatusCode:HTTPCode200OK
                             andNetworkConnected:@YES
                             andRequestValidator:^BOOL(id requestObject) {
                                 XCTAssertTrue([requestObject isKindOfClass:[NSMutableURLRequest class]]);
                                 NSMutableURLRequest *request = requestObject;

                                 NSString *expectedUrl =
                                     [NSString stringWithFormat:@"https://api.keen.io/3.0/projects/%@/"
                                                                @"queries/saved/%@/result",
                                                                kDefaultProjectID, queryName];
                                 XCTAssertEqualObjects(expectedUrl, request.URL.absoluteString);
                                 return @YES;
                             }];

    // Run the saved query request
    [mock runAsyncSavedAnalysis:queryName
              completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
                  XCTAssertNil(error);

                  // Validate the http code
                  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                  XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

                  // Deserialize the response dictionary
                  NSDictionary *responseDictionary =
                      [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];

                  // Get the result from the response dictionary
                  NSNumber *result = [responseDictionary objectForKey:@"result"];

                  // Assert that the result is as expected
                  XCTAssertEqualObjects(result, expectedResult);

                  [queryCompleted fulfill];
              }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

- (void)testSavedCountQuerySuccess {
    NSString *queryName = @"saved_count";
    NSNumber *resultValue = @880;

    NSDictionary *responseDictionary = @{
        @"refresh_rate" : @0,
        @"user_last_modified_date" : @"2017-05-09T21:28:12.408000+00:00",
        @"last_modified_date" : @"2017-05-09T21:28:12.408000+00:00",
        @"query_name" : queryName,
        @"result" : resultValue,
        @"urls" : [self urlsForSavedQuery:queryName withProjectID:kDefaultProjectID],
        @"created_date" : @"2017-05-09T21:28:12.408000+00:00",
        @"query" : @{
            @"target_property" : @"price",
            @"event_collection" : @"purchases2",
            @"filters" : @[],
            @"interval" : [NSNull null],
            @"group_by" : [NSNull null],
            @"analysis_type" : @"sum",
            @"timezone" : [NSNull null],
            @"timeframe" : @"this_2_weeks"
        },
        @"metadata" : [NSNull null],
        @"run_information" : [NSNull null]
    };

    [self makeAndValidateSavedQueryRequest:queryName
                    withResponseDictionary:responseDictionary
                        withExpectedResult:resultValue];
}

- (void)testSavedFunnelQuerySuccess {
    NSString *queryName = @"saved_funnel";
    NSDictionary *resultValue = @{
        @"steps" : @[
            @{
               @"with_actors" : @NO,
               @"actor_property" : @"visitor.guid",
               @"filters" : @[],
               @"timeframe" : @"this_7_days",
               @"timezone" : [NSNull null],
               @"event_collection" : @"signed up",
               @"optional" : @NO,
               @"inverted" : @NO
            },
            @{
               @"with_actors" : @NO,
               @"actor_property" : @"user.guid",
               @"filters" : @[],
               @"timeframe" : @"this_7_days",
               @"timezone" : [NSNull null],
               @"event_collection" : @"completed profile",
               @"optional" : @NO,
               @"inverted" : @NO
            },
            @{
               @"with_actors" : @NO,
               @"actor_property" : @"user.guid",
               @"filters" : @[],
               @"timeframe" : @"this_7_days",
               @"timezone" : [NSNull null],
               @"event_collection" : @"referred user",
               @"optional" : @NO,
               @"inverted" : @NO
            }
        ],
        @"result" : @[ @0, @0, @0 ]
    };

    NSDictionary *responseDictionary = @{
        @"refresh_rate" : @0,
        @"user_last_modified_date" : @"2017-05-10T16:44:44.358000+00:00",
        @"last_modified_date" : @"2017-05-10T16:44:44.358000+00:00",
        @"query_name" : queryName,
        @"result" : resultValue,
        @"urls" : [self urlsForSavedQuery:queryName withProjectID:kDefaultProjectID],
        @"created_date" : @"2017-05-10T16:44:44.358000+00:00",
        @"query" : @{
            @"analysis_type" : @"funnel",
            @"timezone" : [NSNull null],
            @"steps" : @[
                @{
                   @"with_actors" : @NO,
                   @"actor_property" : @"visitor.guid",
                   @"filters" : @[],
                   @"timeframe" : @"this_7_days",
                   @"timezone" : [NSNull null],
                   @"event_collection" : @"signed up",
                   @"optional" : @NO,
                   @"inverted" : @NO
                },
                @{
                   @"with_actors" : @NO,
                   @"actor_property" : @"user.guid",
                   @"filters" : @[],
                   @"timeframe" : @"this_7_days",
                   @"timezone" : [NSNull null],
                   @"event_collection" : @"completed profile",
                   @"optional" : @NO,
                   @"inverted" : @NO
                },
                @{
                   @"with_actors" : @NO,
                   @"actor_property" : @"user.guid",
                   @"filters" : @[],
                   @"timeframe" : @"this_7_days",
                   @"timezone" : [NSNull null],
                   @"event_collection" : @"referred user",
                   @"optional" : @NO,
                   @"inverted" : @NO
                }
            ],
            @"timeframe" : [NSNull null]
        },
        @"metadata" : [NSNull null],
        @"run_information" : [NSNull null]
    };

    [self makeAndValidateSavedQueryRequest:queryName
                    withResponseDictionary:responseDictionary
                        withExpectedResult:resultValue];
}

- (void)testSavedMultiAnalysisQuerySuccess {
    NSString *queryName = @"saved_multi";
    NSDictionary *resultValue = @{ @"total visits" : @100, @"unique users" : @55 };

    NSDictionary *responseDictionary = @{
        @"refresh_rate" : @0,
        @"user_last_modified_date" : @"2017-05-10T17:13:44.932000+00:00",
        @"last_modified_date" : @"2017-05-10T17:13:44.932000+00:00",
        @"query_name" : queryName,
        @"result" : resultValue,
        @"urls" : [self urlsForSavedQuery:queryName withProjectID:kDefaultProjectID],
        @"created_date" : @"2017-05-10T17:13:44.932000+00:00",
        @"query" : @{
            @"event_collection" : @"signed up",
            @"filters" : @[],
            @"interval" : [NSNull null],
            @"group_by" : [NSNull null],
            @"analysis_type" : @"multi_analysis",
            @"timezone" : [NSNull null],
            @"analyses" : @{
                @"total visits" : @{@"analysis_type" : @"count", @"target_property" : [NSNull null]},
                @"unique users" : @{@"analysis_type" : @"count_unique", @"target_property" : @"user.id"}
            },
            @"timeframe" : @"this_7_days"
        },
        @"metadata" : [NSNull null],
        @"run_information" : [NSNull null]
    };

    [self makeAndValidateSavedQueryRequest:queryName
                    withResponseDictionary:responseDictionary
                        withExpectedResult:resultValue];
}

@end
