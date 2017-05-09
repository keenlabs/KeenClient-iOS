//
//  KeenEventTests.m
//  KeenClient
//
//  Created by Brian Baumhover on 5/8/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenClient.h"
#import "KIOUtil.h"
#import "HTTPCodes.h"

#import "KeenClientTestable.h"
#import "KeenTestConstants.h"
#import "KeenTestCaseBase.h"
#import "KeenEventTests.h"

@implementation KeenEventTests

- (void)testAddEvent {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    KeenClient *clientI = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    
    // nil dict should should do nothing
    NSError *error = nil;
    XCTAssertFalse([client addEvent:nil toEventCollection:@"foo" error:&error], @"addEvent should fail");
    XCTAssertNotNil(error, @"nil dict should return NO");
    error = nil;
    
    XCTAssertFalse([clientI addEvent:nil toEventCollection:@"foo" error:&error], @"addEvent should fail");
    XCTAssertNotNil(error, @"nil dict should return NO");
    error = nil;
    
    // nil collection should do nothing
    XCTAssertFalse([client addEvent:[NSDictionary dictionary] toEventCollection:nil error:&error], @"addEvent should fail");
    XCTAssertNotNil(error, @"nil collection should return NO");
    error = nil;
    
    XCTAssertFalse([clientI addEvent:[NSDictionary dictionary] toEventCollection:nil error:&error], @"addEvent should fail");
    XCTAssertNotNil(error, @"nil collection should return NO");
    error = nil;
    
    // basic dict should work
    NSArray *keys = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    NSArray *values = [NSArray arrayWithObjects:@"apple", @"bapple", [NSNull null], nil];
    NSDictionary *event = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    XCTAssertTrue([client addEvent:event toEventCollection:@"foo" error:&error], @"addEvent should succeed");
    XCTAssertNil(error, @"no error should be returned");
    XCTAssertTrue([clientI addEvent:event toEventCollection:@"foo" error:&error], @"addEvent should succeed");
    XCTAssertNil(error, @"an okay event should return YES");
    error = nil;
    
    // dict with NSDate should work
    event = @{@"a": @"apple", @"b": @"bapple", @"a_date": [NSDate date]};
    XCTAssertTrue([client addEvent:event toEventCollection:@"foo" error:&error], @"addEvent should succeed");
    XCTAssertNil(error, @"no error should be returned");
    XCTAssertTrue([clientI addEvent:event toEventCollection:@"foo" error:&error], @"addEvent should succeed");
    XCTAssertNil(error, @"an event with a date should return YES");
    error = nil;
    
    // dict with non-serializable value should do nothing
    NSError *badValue = [[NSError alloc] init];
    event = @{@"a": @"apple", @"b": @"bapple", @"bad_key": badValue};
    XCTAssertFalse([client addEvent:event toEventCollection:@"foo" error:&error], @"addEvent should fail");
    XCTAssertNotNil(error, @"an event that can't be serialized should return NO");
    XCTAssertNotNil([[error userInfo] objectForKey:NSUnderlyingErrorKey], @"and event that can't be serialized should return the underlaying error");
    error = nil;
    
    XCTAssertFalse([clientI addEvent:event toEventCollection:@"foo" error:&error], @"addEvent should fail");
    XCTAssertNotNil(error, @"an event that can't be serialized should return NO");
    XCTAssertNotNil([[error userInfo] objectForKey:NSUnderlyingErrorKey], @"and event that can't be serialized should return the underlaying error");
    error = nil;
    
    // dict with root keen prop should do nothing
    badValue = [[NSError alloc] init];
    event = @{@"a": @"apple", @"keen": @"bapple"};
    XCTAssertFalse([client addEvent:event toEventCollection:@"foo" error:&error], @"addEvent should fail");
    XCTAssertNotNil(error, @"");
    error = nil;
    
    XCTAssertFalse([clientI addEvent:event toEventCollection:@"foo" error:&error], @"addEvent should fail");
    XCTAssertNotNil(error, @"");
    error = nil;
    
    // dict with non-root keen prop should work
    error = nil;
    event = @{@"nested": @{@"keen": @"whatever"}};
    XCTAssertTrue([client addEvent:event toEventCollection:@"foo" error:nil], @"addEvent should succeed");
    XCTAssertNil(error, @"no error should be returned");
    XCTAssertTrue([clientI addEvent:event toEventCollection:@"foo" error:nil], @"addEvent should succeed");
    XCTAssertNil(error, @"an okay event should return YES");
}

- (void)testAddEventNoWriteKey {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:nil andReadKey:nil];
    KeenClient *clientI = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:nil andReadKey:nil];
    
    NSArray *keys = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    NSArray *values = [NSArray arrayWithObjects:@"apple", @"bapple", [NSNull null], nil];
    NSDictionary *event = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    XCTAssertThrows([client addEvent:event toEventCollection:@"foo" error:nil], @"should throw an exception");
    XCTAssertThrows([clientI addEvent:event toEventCollection:@"foo" error:nil], @"should throw an exception");
}

- (void)testEventWithTimestamp {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    KeenClient *clientI = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    
    NSDate *date = [NSDate date];
    KeenProperties *keenProperties = [[KeenProperties alloc] init];
    keenProperties.timestamp = date;
    [client addEvent:@{@"a": @"b"} withKeenProperties:keenProperties toEventCollection:@"foo" error:nil];
    [clientI addEvent:@{@"a": @"b"} withKeenProperties:keenProperties toEventCollection:@"foo" error:nil];
    
    NSDictionary *eventsForCollection = [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID] objectForKey:@"foo"];
    // Grab the first event we get back
    NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
    NSError *error = nil;
    NSDictionary *deserializedDict = [NSJSONSerialization JSONObjectWithData:eventData
                                                                     options:0
                                                                       error:&error];
    
    NSString *deserializedDate = deserializedDict[@"keen"][@"timestamp"];
    NSString *originalDate = [KIOUtil convertDate:date];
    XCTAssertEqualObjects(originalDate, deserializedDate, @"If a timestamp is specified it should be used.");
    originalDate = [KIOUtil convertDate:date];
    XCTAssertEqualObjects(originalDate, deserializedDate, @"If a timestamp is specified it should be used.");
}

- (void)testEventWithLocation {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    KeenClient *clientI = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    
    KeenProperties *keenProperties = [[KeenProperties alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:37.73 longitude:-122.47];
    keenProperties.location = location;
    [client addEvent:@{@"a": @"b"} withKeenProperties:keenProperties toEventCollection:@"foo" error:nil];
    [clientI addEvent:@{@"a": @"b"} withKeenProperties:keenProperties toEventCollection:@"foo" error:nil];
    
    NSDictionary *eventsForCollection = [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID] objectForKey:@"foo"];
    // Grab the first event we get back
    NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
    NSError *error = nil;
    NSDictionary *deserializedDict = [NSJSONSerialization JSONObjectWithData:eventData
                                                                     options:0
                                                                       error:&error];
    
    NSDictionary *deserializedLocation = deserializedDict[@"keen"][@"location"];
    NSArray *deserializedCoords = deserializedLocation[@"coordinates"];
    XCTAssertEqualObjects(@-122.47, deserializedCoords[0], @"Longitude was incorrect.");
    XCTAssertEqualObjects(@37.73, deserializedCoords[1], @"Latitude was incorrect.");
}

- (void)testEventWithDictionary {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    KeenClient *clientI = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    
    NSString* json = @"{\"test_str_array\":[\"val1\",\"val2\",\"val3\"]}";
    NSDictionary* eventDictionary = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    [client addEvent:eventDictionary toEventCollection:@"foo" error:nil];
    [clientI addEvent:eventDictionary toEventCollection:@"foo" error:nil];
    NSDictionary *eventsForCollection = [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID] objectForKey:@"foo"];
    // Grab the first event we get back
    NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
    NSError *error = nil;
    NSDictionary *deserializedDict = [NSJSONSerialization JSONObjectWithData:eventData
                                                                     options:0
                                                                       error:&error];
    
    XCTAssertEqualObjects(@"val1", deserializedDict[@"test_str_array"][0], @"array was incorrect");
    XCTAssertEqualObjects(@"val2", deserializedDict[@"test_str_array"][1], @"array was incorrect");
    XCTAssertEqualObjects(@"val3", deserializedDict[@"test_str_array"][2], @"array was incorrect");
}

- (void)testEventWithNonDictionaryKeen {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    KeenClient *clientI = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    
    NSDictionary *theEvent = @{@"keen": @"abc"};
    NSError *error = nil;
    [client addEvent:theEvent toEventCollection:@"foo" error:&error];
    [clientI addEvent:theEvent toEventCollection:@"foo" error:&error];
    XCTAssertNotNil(error, @"an event with a non-dict value for 'keen' should error");
}

- (void)addSimpleEventAndUploadWithMock:(id)mock andFinishedBlock:(void (^)())finishedBlock {
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    
    // and "upload" it
    [mock uploadWithFinishedBlock:finishedBlock];
}

# pragma mark - test upload

-(void)testUploadWithNoEvents {
    XCTestExpectation* uploadFinishedBlockCalled = [self expectationWithDescription:@"Upload should finish."];
    
    id mock = [self createClientWithResponseData:nil andStatusCode:HTTPCode200OK];
    
    [mock uploadWithFinishedBlock:^{
        [uploadFinishedBlockCalled fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        XCTAssertEqual([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID],
                       0,
                       @"Upload method should return with message Request data is empty.");
    }];
}

- (void)testUploadSuccess {
    id mock = [self createClientWithResponseData:nil andStatusCode:HTTPCode2XXSuccess];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 0, @"There should be no files after a successful upload.");
    }];
}

- (void)testUploadSuccessInstanceClient {
    id mock = [self createClientWithResponseData:nil andStatusCode:HTTPCode2XXSuccess];
    
    // make sure the event was deleted from the store
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 0, @"There should be no files after a successful upload.");
    }];
}

- (void)testUploadFailedServerDown {
    id mock = [self createClientWithResponseData:nil andStatusCode:HTTPCode500InternalServerError];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file wasn't deleted from the store
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1, @"There should be one file after a failed upload.");
    }];
}

- (void)testUploadFailedServerDownInstanceClient {
    id mock = [self createClientWithResponseData:nil andStatusCode:HTTPCode500InternalServerError];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file wasn't deleted from the store
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1, @"There should be one file after a failed upload.");
    }];
}

- (void)testUploadFailedServerDownNonJsonResponse {
    id mock = [self createClientWithResponseData:@{} andStatusCode:HTTPCode500InternalServerError];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file wasn't deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1, @"There should be one file after a failed upload.");
    }];
}

- (void)testUploadFailedServerDownNonJsonResponseInstanceClient {
    id mock = [self createClientWithResponseData:@{} andStatusCode:HTTPCode500InternalServerError];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file wasn't deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1, @"There should be one file after a failed upload.");
    }];
}


- (void)testDeleteAfterMaxAttempts {
    id mock = [self createClientWithResponseData:nil andStatusCode:HTTPCode500InternalServerError];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    // and "upload" it
    [mock uploadWithFinishedBlock:^{
        // make sure the file wasn't deleted from the store
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1, @"There should be one file after an unsuccessful attempts.");
        
        // add another event
        [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
        [mock uploadWithFinishedBlock:^{
            // make sure both files weren't deleted from the store
            XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 2, @"There should be two files after 2 unsuccessful attempts.");
            
            [mock uploadWithFinishedBlock:^{
                // make sure the first file was deleted from the store, but the second one remains
                XCTAssertTrue([[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:[mock config].projectID] allKeys].count == 1, @"There should be one file after 3 unsuccessful attempts.");
                
                [mock uploadWithFinishedBlock:^{
                    [responseArrived fulfill];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure both files were deleted from the store
        XCTAssertTrue([[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:[mock config].projectID] allKeys].count == 0, @"There should be no files after 3 unsuccessfull attempts.");
    }];
}

- (void)testIncrementEvenOnNoResponse {
    // mock an empty response from the server
    id mock = [self createClientWithResponseData:@{} andStatusCode:HTTPCode200OK];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    // and "upload" it
    [mock uploadWithFinishedBlock:^{
        // make sure the file wasn't deleted from the store
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1, @"There should be one event after an unsuccessful attempt.");
        
        // add another event
        [mock uploadWithFinishedBlock:^{
            // make sure both files weren't deleted from the store
            XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1, @"There should be one event after 2 unsuccessful attempts.");
            
            [mock uploadWithFinishedBlock:^{
                [responseArrived fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the event was incremented
        XCTAssertTrue([[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:[mock config].projectID] allKeys].count == 0, @"There should be no events with less than 3 unsuccessful attempts.");
        XCTAssertTrue([[KIODBStore.sharedInstance getEventsWithMaxAttempts:4 andProjectID:[mock config].projectID] allKeys].count == 1, @"There should be one event with less than 4 unsuccessful attempts.");
    }];
}

- (void)testUploadFailedBadRequest {
    id mock = [self createClientWithResponseData:[self buildResponseJsonWithSuccess:NO
                                                                       AndErrorCode:@"InvalidCollectionNameError"
                                                                     AndDescription:@"anything"]
                                   andStatusCode:HTTPCode200OK];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file was deleted locally
        // make sure the event was deleted from the store
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:nil] == 0,  @"An invalid event should be deleted after an upload attempt.");
    }];
}

- (void)testUploadFailedBadRequestInstanceClient {
    id mock = [self createClientWithResponseData:[self buildResponseJsonWithSuccess:NO
                                                                       AndErrorCode:@"InvalidCollectionNameError"
                                                                     AndDescription:@"anything"]
                                   andStatusCode:HTTPCode200OK];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file was deleted locally
        // make sure the event was deleted from the store
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:nil] == 0,  @"An invalid event should be deleted after an upload attempt.");
    }];
}

- (void)testUploadFailedBadRequestUnknownError {
    id mock = [self createClientWithResponseData:@{} andStatusCode:HTTPCode400BadRequest];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file wasn't deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1, @"An upload that results in an unexpected error should not delete the event.");
    }];
}

- (void)testUploadFailedBadRequestUnknownErrorInstanceClient {
    id mock = [self createClientWithResponseData:@{} andStatusCode:HTTPCode400BadRequest];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file wasn't deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1, @"An upload that results in an unexpected error should not delete the event.");
    }];
}

- (void)testUploadFailedRedirectionStatus {
    id mock = [self createClientWithResponseData:@{} andStatusCode:HTTPCode300MultipleChoices];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file wasn't deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1, @"An upload that results in an unexpected error should not delete the event.");
    }];
}

- (void)testUploadFailedRedirectionStatusInstanceClient {
    id mock = [self createClientWithResponseData:@{} andStatusCode:HTTPCode300MultipleChoices];
    
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file wasn't deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1, @"An upload that results in an unexpected error should not delete the event.");
    }];
}

- (void)testUploadSkippedNoNetwork {
    XCTestExpectation* uploadFinishedBlockCalled = [self expectationWithDescription:@"Upload finished block should be called."];
    
    id mock = [self createClientWithResponseData:nil andStatusCode:HTTPCode200OK andNetworkConnected:@NO];
    
    [self addSimpleEventAndUploadWithMock:mock andFinishedBlock:^{
        [uploadFinishedBlockCalled fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file wasn't deleted locally
        XCTAssertEqual([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID],
                       1,
                       @"An upload with no network should not delete the event.");
    }];
}

- (void)testUploadMultipleEventsSameCollectionSuccess {
    NSDictionary *result1 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result2 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:result1, result2, nil]
                                                       forKey:@"foo"];
    id mock = [self createClientWithResponseData:result andStatusCode:HTTPCode200OK];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple2" forKey:@"a"] toEventCollection:@"foo" error:nil];
    
    // and "upload" it
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [mock uploadWithFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the events were deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:nil] == 0,  @"There should be no files after a successful upload.");
    }];
}

- (void)testUploadMultipleEventsSameCollectionSuccessInstanceClient {
    NSDictionary *result1 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result2 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:result1, result2, nil]
                                                       forKey:@"foo"];
    id mock = [self createClientWithResponseData:result andStatusCode:HTTPCode200OK];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple2" forKey:@"a"] toEventCollection:@"foo" error:nil];
    
    // and "upload" it
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [mock uploadWithFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the events were deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:nil] == 0,  @"There should be no files after a successful upload.");
    }];
}

- (void)testUploadMultipleEventsDifferentCollectionSuccess {
    NSDictionary *result1 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result2 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSArray arrayWithObject:result1], @"foo",
                            [NSArray arrayWithObject:result2], @"bar", nil];
    id mock = [self createClientWithResponseData:result andStatusCode:HTTPCode200OK];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] toEventCollection:@"bar" error:nil];
    
    // and "upload" it
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [mock uploadWithFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the files were deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:nil] == 0,  @"There should be no events after a successful upload.");
    }];
}

- (void)testUploadMultipleEventsDifferentCollectionSuccessInstanceClient {
    NSDictionary *result1 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result2 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSArray arrayWithObject:result1], @"foo",
                            [NSArray arrayWithObject:result2], @"bar", nil];
    id mock = [self createClientWithResponseData:result andStatusCode:HTTPCode200OK];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] toEventCollection:@"bar" error:nil];
    
    // and "upload" it
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [mock uploadWithFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the files were deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:nil] == 0,  @"There should be no events after a successful upload.");
    }];
}

- (void)testUploadMultipleEventsSameCollectionOneFails {
    NSDictionary *result1 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result2 = [self buildResultWithSuccess:NO
                                            andErrorCode:@"InvalidCollectionNameError"
                                          andDescription:@"something"];
    NSDictionary *result = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:result1, result2, nil]
                                                       forKey:@"foo"];
    id mock = [self createClientWithResponseData:result andStatusCode:HTTPCode200OK];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple2" forKey:@"a"] toEventCollection:@"foo" error:nil];
    
    // and "upload" it
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [mock uploadWithFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file were deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 0,  @"There should be no events after a successful upload.");
    }];
}

- (void)testUploadMultipleEventsSameCollectionOneFailsInstanceClient {
    NSDictionary *result1 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result2 = [self buildResultWithSuccess:NO
                                            andErrorCode:@"InvalidCollectionNameError"
                                          andDescription:@"something"];
    NSDictionary *result = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:result1, result2, nil]
                                                       forKey:@"foo"];
    id mock = [self createClientWithResponseData:result andStatusCode:HTTPCode200OK];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple2" forKey:@"a"] toEventCollection:@"foo" error:nil];
    
    // and "upload" it
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [mock uploadWithFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the file were deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 0,  @"There should be no events after a successful upload.");
    }];
}

- (void)testUploadMultipleEventsDifferentCollectionsOneFails {
    NSDictionary *result1 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result2 = [self buildResultWithSuccess:NO
                                            andErrorCode:@"InvalidCollectionNameError"
                                          andDescription:@"something"];
    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSArray arrayWithObject:result1], @"foo",
                            [NSArray arrayWithObject:result2], @"bar", nil];
    id mock = [self createClientWithResponseData:result andStatusCode:HTTPCode200OK];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] toEventCollection:@"bar" error:nil];
    
    // and "upload" it
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [mock uploadWithFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the files were deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 0,  @"There should be no events after a successful upload.");
    }];
}

- (void)testUploadMultipleEventsDifferentCollectionsOneFailsInstanceClient {
    NSDictionary *result1 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result2 = [self buildResultWithSuccess:NO
                                            andErrorCode:@"InvalidCollectionNameError"
                                          andDescription:@"something"];
    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSArray arrayWithObject:result1], @"foo",
                            [NSArray arrayWithObject:result2], @"bar", nil];
    id mock = [self createClientWithResponseData:result andStatusCode:HTTPCode200OK];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] toEventCollection:@"bar" error:nil];
    
    // and "upload" it
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [mock uploadWithFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the files were deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 0,  @"There should be no events after a successful upload.");
    }];
}

- (void)testUploadMultipleEventsDifferentCollectionsOneFailsForServerReason {
    NSDictionary *result1 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result2 = [self buildResultWithSuccess:NO
                                            andErrorCode:@"barf"
                                          andDescription:@"something"];
    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSArray arrayWithObject:result1], @"foo",
                            [NSArray arrayWithObject:result2], @"bar", nil];
    id mock = [self createClientWithResponseData:result andStatusCode:HTTPCode200OK];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] toEventCollection:@"bar" error:nil];
    
    // and "upload" it
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [mock uploadWithFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the files were deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1,  @"There should be 1 events after a partial upload.");
    }];
}

- (void)testUploadMultipleEventsDifferentCollectionsOneFailsForServerReasonInstanceClient {
    NSDictionary *result1 = [self buildResultWithSuccess:YES
                                            andErrorCode:nil
                                          andDescription:nil];
    NSDictionary *result2 = [self buildResultWithSuccess:NO
                                            andErrorCode:@"barf"
                                          andDescription:@"something"];
    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSArray arrayWithObject:result1], @"foo",
                            [NSArray arrayWithObject:result2], @"bar", nil];
    id mock = [self createClientWithResponseData:result andStatusCode:HTTPCode200OK];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] toEventCollection:@"bar" error:nil];
    
    // and "upload" it
    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
    [mock uploadWithFinishedBlock:^{
        [responseArrived fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:^(NSError * _Nullable error) {
        // make sure the files were deleted locally
        XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:[mock config].projectID] == 1,  @"There should be 1 event after a partial upload.");
    }];
}

- (void)testTooManyEventsCached {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:@"bar", @"foo", nil];
    // create 5 events
    for (int i=0; i<5; i++) {
        [client addEvent:event toEventCollection:@"something" error:nil];
    }
    XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:client.config.projectID] == 5,  @"There should be exactly five events.");
    // now do one more, should age out 1 old ones
    [client addEvent:event toEventCollection:@"something" error:nil];
    // so now there should be 4 left (5 - 2 + 1)
    XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:client.config.projectID] == 4, @"There should be exactly four events.");
}

- (void)testTooManyEventsCachedInstanceClient {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:@"bar", @"foo", nil];
    // create 5 events
    for (int i=0; i<5; i++) {
        [client addEvent:event toEventCollection:@"something" error:nil];
    }
    XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:client.config.projectID] == 5,  @"There should be exactly five events.");
    // now do one more, should age out 1 old ones
    [client addEvent:event toEventCollection:@"something" error:nil];
    // so now there should be 4 left (5 - 2 + 1)
    XCTAssertTrue([KIODBStore.sharedInstance getTotalEventCountWithProjectID:client.config.projectID] == 4, @"There should be exactly four events.");
}

@end
