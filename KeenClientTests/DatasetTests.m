//
//  DatasetTests.m
//  KeenClient
//
//  Created by Brian Baumhover on 5/24/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "HTTPCodes.h"
#import "KeenClient.h"

#import "KeenTestConstants.h"

#import "DatasetTests.h"

@implementation DatasetTests

- (void)testDatasetQuery {
    XCTestExpectation *queryCompleted =
        [self expectationWithDescription:@"runAsyncDatasetQuery should call completionHandler."];

    NSString *datasetName = @"test_dataset";
    NSString *indexValue = @"0";
    NSString *timeframe = @"this_10_days";

    // Load a canned response from a file
    NSString *jsonPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"DatasetResponseBody" ofType:@"json"];
    NSData *responseData = [[NSData alloc] initWithContentsOfFile:jsonPath];
    NSError *error;
    NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:nil error:&error];
    XCTAssertNil(error);
    // Save the result for later validation
    NSArray *expectedResult = [responseDictionary objectForKey:@"result"];

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
                                                                @"datasets/%@/results?index_by=%@&timeframe=%@",
                                                                kDefaultProjectID,
                                                                datasetName,
                                                                indexValue,
                                                                timeframe];
                                 XCTAssertEqualObjects(expectedUrl, request.URL.absoluteString);
                                 return @YES;
                             }];

    // Make the request and validate the results
    [mock runAsyncDatasetQuery:datasetName
                    indexValue:indexValue
                     timeframe:timeframe
             completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
                 XCTAssertNil(error);

                 // Validate the http code
                 NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                 XCTAssertEqual([httpResponse statusCode], HTTPCode200OK);

                 // Deserialize the response dictionary
                 NSDictionary *responseDictionary =
                     [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];

                 // Get the result from the response dictionary
                 NSArray *result = [responseDictionary objectForKey:@"result"];

                 // Assert that the result is as expected
                 XCTAssertEqualObjects(result, expectedResult);
                 [queryCompleted fulfill];
             }];

    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

@end
