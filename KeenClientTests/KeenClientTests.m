//
//  KeenClientTests.m
//  KeenClientTests
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenClientTests.h"
#import "KeenClient.h"
#import <OCMock/OCMock.h>
#import "KeenConstants.h"
#import "KeenProperties.h"


@interface KeenClient (testability)

// The project ID for this particular client.
@property (nonatomic, retain) NSString *projectId;
@property (nonatomic, retain) NSString *writeKey;
@property (nonatomic, retain) NSString *readKey;

// If we're running tests.
@property (nonatomic) Boolean isRunningTests;

- (NSData *)sendEvents: (NSData *) data returningResponse: (NSURLResponse **) response error: (NSError **) error;
- (id)convertDate: (id) date;
- (id)handleInvalidJSONInObject:(id)value;

@end

@interface KeenClientTests ()

- (NSString *)cacheDirectory;
- (NSString *)keenDirectory;
- (NSString *)eventDirectoryForCollection:(NSString *)collection;
- (NSArray *)contentsOfDirectoryForCollection:(NSString *)collection;
- (NSDictionary *)firstEventForCollection:(NSString *)collection;

@end

@implementation KeenClientTests

- (void)setUp {
    [super setUp];
    
    // Set-up code here.
    [[KeenClient sharedClient] setProjectId:nil];
    [[KeenClient sharedClient] setWriteKey:nil];
    [[KeenClient sharedClient] setReadKey:nil];
}

- (void)tearDown {
    // Tear-down code here.
    NSLog(@"\n");
    
    // delete all collections and their events.
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[self keenDirectory]]) {
        [fileManager removeItemAtPath:[self keenDirectory] error:&error];
        if (error) {
            STFail(@"No error should be thrown when cleaning up: %@", [error localizedDescription]);
        }
    }
    
    [super tearDown];
}

- (void)testInitWithProjectId{
    KeenClient *client = [[KeenClient alloc] initWithProjectId:@"something" andWriteKey:@"wk" andReadKey:@"rk"];
    STAssertEqualObjects(@"something", client.projectId, @"init with a valid project id should work");
    STAssertEqualObjects(@"wk", client.writeKey, @"init with a valid project id should work");
    STAssertEqualObjects(@"rk", client.readKey, @"init with a valid project id should work");
    
    KeenClient *client2 = [[KeenClient alloc] initWithProjectId:@"another" andWriteKey:@"wk2" andReadKey:@"rk2"];
    STAssertEqualObjects(@"another", client2.projectId, @"init with a valid project id should work");
    STAssertEqualObjects(@"wk2", client2.writeKey, @"init with a valid project id should work");
    STAssertEqualObjects(@"rk2", client2.readKey, @"init with a valid project id should work");
    STAssertTrue(client != client2, @"Another init should return a separate instance");
    
    [client release];
    [client2 release];
    
    client = [[KeenClient alloc] initWithProjectId:nil andWriteKey:@"wk" andReadKey:@"rk"];
    STAssertNil(client, @"init with a nil project ID should return nil");
}

- (void)testSharedClientWithProjectId{
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];
    STAssertEquals(@"id", client.projectId, @"sharedClientWithProjectId with a non-nil project id should work.");
    STAssertEqualObjects(@"wk", client.writeKey, @"init with a valid project id should work");
    STAssertEqualObjects(@"rk", client.readKey, @"init with a valid project id should work");
    
    KeenClient *client2 = [KeenClient sharedClientWithProjectId:@"other" andWriteKey:@"wk2" andReadKey:@"rk2"];
    STAssertEqualObjects(client, client2, @"sharedClient should return the same instance");
    STAssertEqualObjects(@"wk2", client2.writeKey, @"sharedClient with a valid project id should work");
    STAssertEqualObjects(@"rk2", client2.readKey, @"sharedClient with a valid project id should work");
    
    client = [KeenClient sharedClientWithProjectId:nil andWriteKey:@"wk" andReadKey:@"rk"];
    STAssertNil(client, @"sharedClient with an invalid project id should return nil");
}

- (void)testSharedClient {
    KeenClient *client = [KeenClient sharedClient];
    STAssertNil(client.projectId, @"a client's project id should be nil at first");
    STAssertNil(client.writeKey, @"a client's write key should be nil at first");
    STAssertNil(client.readKey, @"a client's read key should be nil at first");
    
    KeenClient *client2 = [KeenClient sharedClient];
    STAssertEqualObjects(client, client2, @"sharedClient should return the same instance");
}

- (void)testAddEvent {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];
    
    // nil dict should should do nothing
    NSError *error = nil;
    [client addEvent:nil toEventCollection:@"foo" error:&error];
    STAssertNotNil(error, @"nil dict should return NO");
    error = nil;
    
    // nil collection should do nothing
    [client addEvent:[NSDictionary dictionary] toEventCollection:nil error:&error];
    STAssertNotNil(error, @"nil collection should return NO");
    error = nil;
    
    // basic dict should work
    NSArray *keys = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    NSArray *values = [NSArray arrayWithObjects:@"apple", @"bapple", [NSNull null], nil];
    NSDictionary *event = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    [client addEvent:event toEventCollection:@"foo" error:&error];
    STAssertNil(error, @"an okay event should return YES");
    error = nil;
    // now go find the file we wrote to disk
    NSDictionary *deserializedDict = [self firstEventForCollection:@"foo"];
    // make sure timestamp was added
    STAssertNotNil(deserializedDict, @"The event should have been written to disk.");
    STAssertNotNil(deserializedDict[@"keen"], @"The event should have a keen namespace.");
    STAssertNotNil(deserializedDict[@"keen"][@"timestamp"], @"The event written to disk should have had a timestamp added: %@", deserializedDict);
    STAssertEqualObjects(@"apple", deserializedDict[@"a"], @"Value for key 'a' is wrong.");
    STAssertEqualObjects(@"bapple", deserializedDict[@"b"], @"Value for key 'b' is wrong.");
    STAssertEqualObjects([NSNull null], deserializedDict[@"c"], @"Value for key 'c' is wrong.");
    
    // dict with NSDate should work
    event = @{@"a": @"apple", @"b": @"bapple", @"a_date": [NSDate date]};
    [client addEvent:event toEventCollection:@"foo" error:&error];
    STAssertNil(error, @"an event with a date should return YES");
    error = nil;
    // now there should be two files
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 2, @"There should be two files written.");
    
    // dict with non-serializable value should do nothing
    NSError *badValue = [[NSError alloc] init];
    event = @{@"a": @"apple", @"b": @"bapple", @"bad_key": badValue};
    [client addEvent:event toEventCollection:@"foo" error:&error];
    STAssertNotNil(error, @"an event that can't be serialized should return NO");
    error = nil;
    
    // dict with root keen prop should do nothing
    badValue = [[NSError alloc] init];
    event = @{@"a": @"apple", @"keen": @"bapple"};
    [client addEvent:event toEventCollection:@"foo" error:&error];
    STAssertNotNil(error, @"");
    error = nil;
    
    // dict with non-root keen prop should work
    error = nil;
    event = @{@"nested": @{@"keen": @"whatever"}};
    [client addEvent:event toEventCollection:@"foo" error:nil];
    STAssertNil(error, @"an okay event should return YES");
}

- (void)testAddEventNoWriteKey {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:nil andReadKey:nil];
    
    NSArray *keys = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    NSArray *values = [NSArray arrayWithObjects:@"apple", @"bapple", [NSNull null], nil];
    NSDictionary *event = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    STAssertThrows([client addEvent:event toEventCollection:@"foo" error:nil], @"should throw an exception");
}

- (void)testEventWithTimestamp {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];
    
    NSDate *date = [NSDate date];
    KeenProperties *keenProperties = [[[KeenProperties alloc] init] autorelease];
    keenProperties.timestamp = date;
    [client addEvent:@{@"a": @"b"} withKeenProperties:keenProperties toEventCollection:@"foo" error:nil];
    NSDictionary *deserializedDict = [self firstEventForCollection:@"foo"];
        
    NSString *deserializedDate = deserializedDict[@"keen"][@"timestamp"];
    NSString *originalDate = [client convertDate:date];
    STAssertEqualObjects(originalDate, deserializedDate, @"If a timestamp is specified it should be used.");
}

- (void)testEventWithLocation {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];
    
    KeenProperties *keenProperties = [[[KeenProperties alloc] init] autorelease];
    CLLocation *location = [[[CLLocation alloc] initWithLatitude:37.73 longitude:-122.47] autorelease];
    keenProperties.location = location;
    [client addEvent:@{@"a": @"b"} withKeenProperties:keenProperties toEventCollection:@"foo" error:nil];
    NSDictionary *deserializedDict = [self firstEventForCollection:@"foo"];
    
    NSDictionary *deserializedLocation = deserializedDict[@"keen"][@"location"];
    NSArray *deserializedCoords = deserializedLocation[@"coordinates"];
    STAssertEqualObjects(@-122.47, deserializedCoords[0], @"Longitude was incorrect.");
    STAssertEqualObjects(@37.73, deserializedCoords[1], @"Latitude was incorrect.");
}

- (void)testEventWithDictionary {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];
    
    NSString* json = @"{\"test_str_array\":[\"val1\",\"val2\",\"val3\"]}";
    NSDictionary* eventDictionary = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    [client addEvent:eventDictionary toEventCollection:@"foo" error:nil];
    NSDictionary *deserializedDict = [self firstEventForCollection:@"foo"];
    
    STAssertEqualObjects(@"val1", deserializedDict[@"test_str_array"][0], @"array was incorrect");
    STAssertEqualObjects(@"val2", deserializedDict[@"test_str_array"][1], @"array was incorrect");
    STAssertEqualObjects(@"val3", deserializedDict[@"test_str_array"][2], @"array was incorrect");
}

- (void)testGeoLocation {
    // set up a client with a location
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];
    CLLocation *location = [[[CLLocation alloc] initWithLatitude:37.73 longitude:-122.47] autorelease];
    client.currentLocation = location;
    // add an event
    [client addEvent:@{@"a": @"b"} toEventCollection:@"foo" error:nil];
    // now get the stored event
    NSDictionary *deserializedDict = [self firstEventForCollection:@"foo"];
    NSDictionary *deserializedLocation = deserializedDict[@"keen"][@"location"];
    NSArray *deserializedCoords = deserializedLocation[@"coordinates"];
    STAssertEqualObjects(@-122.47, deserializedCoords[0], @"Longitude was incorrect.");
    STAssertEqualObjects(@37.73, deserializedCoords[1], @"Latitude was incorrect.");
    
    // now try the same thing but disable geo location
    [KeenClient disableGeoLocation];
    // add an event
    [client addEvent:@{@"a": @"b"} toEventCollection:@"bar" error:nil];
    // now get the stored event
    deserializedDict = [self firstEventForCollection:@"bar"];
    deserializedLocation = deserializedDict[@"keen"][@"location"];
    STAssertNil(deserializedLocation, @"No location should have been saved.");
}

- (NSDictionary *)buildResultWithSuccess:(Boolean)success 
                            andErrorCode:(NSString *)errorCode 
                          andDescription:(NSString *)description {
    NSDictionary *result = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithBool:success]
                                                              forKey:@"success"];
    if (!success) {
        NSDictionary *error = [NSDictionary dictionaryWithObjectsAndKeys:errorCode, @"name",
                               description, @"description", nil];
        [result setValue:error forKey:@"error"];
    }
    return result;
}

- (NSDictionary *)buildResponseJsonWithSuccess:(Boolean)success 
                                 AndErrorCode:(NSString *)errorCode 
                               AndDescription:(NSString *)description {
    NSDictionary *result = [self buildResultWithSuccess:success 
                                           andErrorCode:errorCode 
                                         andDescription:description];
    NSArray *array = [NSArray arrayWithObject:result];
    return [NSDictionary dictionaryWithObject:array forKey:@"foo"];
}

- (id)uploadTestHelperWithData:(id)data andStatusCode:(NSInteger)code {
    if (!data) {
        data = [self buildResponseJsonWithSuccess:YES AndErrorCode:nil AndDescription:nil];
    }
    
    // set up the partial mock
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];
    client.isRunningTests = YES;
    id mock = [OCMockObject partialMockForObject:client];
    
    // set up the response we're faking out
    NSHTTPURLResponse *response = [[[NSHTTPURLResponse alloc] initWithURL:nil statusCode:code HTTPVersion:nil headerFields:nil] autorelease];
    
    // serialize the faked out response data
    data = [client handleInvalidJSONInObject:data];
    NSData *serializedData = [NSJSONSerialization dataWithJSONObject:data
                                                             options:0
                                                               error:nil];
    NSString *json = [[NSString alloc] initWithData:serializedData encoding:NSUTF8StringEncoding];    [json release];
    
    // set up the response data we're faking out
    [[[mock stub] andReturn:serializedData] sendEvents:[OCMArg any] 
                                     returningResponse:[OCMArg setTo:response] 
                                                 error:[OCMArg setTo:nil]];
    
    return mock;
}

- (void)addSimpleEventAndUploadWithMock:(id)mock {
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    
    // and "upload" it
    [mock uploadWithFinishedBlock:nil];
}

- (void)testUploadSuccess {
    id mock = [self uploadTestHelperWithData:nil andStatusCode:200];
    
    [self addSimpleEventAndUploadWithMock:mock];
    
    // make sure the file was deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
}

- (void)testUploadFailedServerDown {
    id mock = [self uploadTestHelperWithData:@{} andStatusCode:500];
    
    [self addSimpleEventAndUploadWithMock:mock];
    
    // make sure the file wasn't deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 1, @"There should be one file after a failed upload.");    
}

- (void)testUploadFailedServerDownNonJsonResponse {
    id mock = [self uploadTestHelperWithData:@{} andStatusCode:500];
    
    [self addSimpleEventAndUploadWithMock:mock];
    
    // make sure the file wasnt't deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 1, @"There should be one file after a failed upload.");    
}

- (void)testUploadFailedBadRequest {
    id mock = [self uploadTestHelperWithData:[self buildResponseJsonWithSuccess:NO 
                                                                   AndErrorCode:@"InvalidCollectionNameError" 
                                                                 AndDescription:@"anything"] 
                               andStatusCode:200];
    
    [self addSimpleEventAndUploadWithMock:mock];
    
    // make sure the file was deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 0, @"An invalid event should be deleted after an upload attempt.");
}

- (void)testUploadFailedBadRequestUnknownError {
    id mock = [self uploadTestHelperWithData:@{} andStatusCode:400];
    
    [self addSimpleEventAndUploadWithMock:mock];
    
    // make sure the file wasn't deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 1, @"An upload that results in an unexpected error should not delete the event.");     
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
    id mock = [self uploadTestHelperWithData:result andStatusCode:200];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple2" forKey:@"a"] toEventCollection:@"foo" error:nil];
    
    // and "upload" it
    [mock uploadWithFinishedBlock:nil];
    
    // make sure the file were deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
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
    id mock = [self uploadTestHelperWithData:result andStatusCode:200];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] toEventCollection:@"bar" error:nil];
    
    // and "upload" it
    [mock uploadWithFinishedBlock:nil];
    
    // make sure the files were deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
    contents = [self contentsOfDirectoryForCollection:@"bar"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
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
    id mock = [self uploadTestHelperWithData:result andStatusCode:200];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple2" forKey:@"a"] toEventCollection:@"foo" error:nil];
    
    // and "upload" it
    [mock uploadWithFinishedBlock:nil];
    
    // make sure the file were deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
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
    id mock = [self uploadTestHelperWithData:result andStatusCode:200];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] toEventCollection:@"bar" error:nil];
    
    // and "upload" it
    [mock uploadWithFinishedBlock:nil];
    
    // make sure the files were deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
    contents = [self contentsOfDirectoryForCollection:@"bar"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
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
    id mock = [self uploadTestHelperWithData:result andStatusCode:200];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toEventCollection:@"foo" error:nil];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] toEventCollection:@"bar" error:nil];
    
    // and "upload" it
    [mock uploadWithFinishedBlock:nil];
    
    // make sure the files were deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
    contents = [self contentsOfDirectoryForCollection:@"bar"];
    STAssertTrue([contents count] == 1, @"There should be a file after a failed upload.");
}

- (void)testTooManyEventsCached {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];
    client.isRunningTests = YES;
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:@"bar", @"foo", nil];
    // create 5 events
    for (int i=0; i<5; i++) {
        [client addEvent:event toEventCollection:@"something" error:nil];
    }
    // should be 5 events now
    NSArray *contentsBefore = [self contentsOfDirectoryForCollection:@"something"];
    STAssertTrue([contentsBefore count] == 5, @"There should be exactly five events.");
    // now do one more, should age out 2 old ones
    [client addEvent:event toEventCollection:@"something" error:nil];
    // so now there should be 4 left (5 - 2 + 1)
    NSArray *contentsAfter = [self contentsOfDirectoryForCollection:@"something"];
    STAssertTrue([contentsAfter count] == 4, @"There should be exactly four events.");
}

- (void)testGlobalPropertiesDictionary {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];
    client.isRunningTests = YES;
    
    NSDictionary * (^RunTest)(NSDictionary*, NSUInteger) = ^(NSDictionary *globalProperties,
                                                             NSUInteger expectedNumProperties) {
        NSString *eventCollectionName = [NSString stringWithFormat:@"foo%f", [[NSDate date] timeIntervalSince1970]];
        client.globalPropertiesDictionary = globalProperties;
        NSDictionary *event = @{@"foo": @"bar"};
        [client addEvent:event toEventCollection:eventCollectionName error:nil];
        NSDictionary *storedEvent = [self firstEventForCollection:eventCollectionName];
        STAssertEqualObjects(event[@"foo"], storedEvent[@"foo"], @"");
        STAssertTrue([storedEvent count] == expectedNumProperties + 1, @"");
        return storedEvent;
    };
    
    // a nil dictionary should be okay
    RunTest(nil, 1);
    
    // an empty dictionary should be okay
    RunTest(@{}, 1);
    
    // a dictionary that returns some non-conflicting property names should be okay
    NSDictionary *storedEvent = RunTest(@{@"default_name": @"default_value"}, 2);
    STAssertEqualObjects(@"default_value", storedEvent[@"default_name"], @"");
    
    // a dictionary that returns a conflicting property name should not overwrite the property on
    // the event
    RunTest(@{@"foo": @"some_new_value"}, 1);
}

- (void)testGlobalPropertiesBlock {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];
    client.isRunningTests = YES;
    
    NSDictionary * (^RunTest)(KeenGlobalPropertiesBlock, NSUInteger) = ^(KeenGlobalPropertiesBlock block,
                                                                         NSUInteger expectedNumProperties) {
        NSString *eventCollectionName = [NSString stringWithFormat:@"foo%f", [[NSDate date] timeIntervalSince1970]];
        client.globalPropertiesBlock = block;
        NSDictionary *event = @{@"foo": @"bar"};
        [client addEvent:event toEventCollection:eventCollectionName error:nil];
        NSDictionary *storedEvent = [self firstEventForCollection:eventCollectionName];
        STAssertEqualObjects(event[@"foo"], storedEvent[@"foo"], @"");
        STAssertTrue([storedEvent count] == expectedNumProperties + 1, @"");
        return storedEvent;
    };
    
    // a block that returns nil should be okay
    RunTest(nil, 1);
    
    // a block that returns an empty dictionary should be okay
    RunTest(^NSDictionary *(NSString *eventCollection) {
        return [NSDictionary dictionary];
    }, 1);
    
    // a block that returns some non-conflicting property names should be okay
    NSDictionary *storedEvent = RunTest(^NSDictionary *(NSString *eventCollection) {
        return @{@"default_name": @"default_value"};
    }, 2);
    STAssertEqualObjects(@"default_value", storedEvent[@"default_name"], @"");
    
    // a block that returns a conflicting property name should not overwrite the property on the event
    RunTest(^NSDictionary *(NSString *eventCollection) {
        return @{@"foo": @"some new value"};
    }, 1);
}

- (void)testGlobalPropertiesTogether {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];
    client.isRunningTests = YES;
    
    // properties from the block should take precedence over properties from the dictionary
    // but properties from the event itself should take precedence over all
    client.globalPropertiesDictionary = @{@"default_property": @5, @"foo": @"some_new_value"};
    client.globalPropertiesBlock = ^NSDictionary *(NSString *eventCollection) {
        return @{ @"default_property": @6, @"foo": @"some_other_value"};
    };
    [client addEvent:@{@"foo": @"bar"} toEventCollection:@"apples" error:nil];
    NSDictionary *storedEvent = [self firstEventForCollection:@"apples"];
    STAssertEqualObjects(@"bar", storedEvent[@"foo"], @"");
    STAssertEqualObjects(@6, storedEvent[@"default_property"], @"");
    STAssertTrue([storedEvent count] == 3, @"");
}

- (void)testInvalidEventCollection {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];
    client.isRunningTests = YES;
    
    NSDictionary *event = @{@"a": @"b"};
    // collection can't start with $
    NSError *error = nil;
    [client addEvent:event toEventCollection:@"$asd" error:&error];
    STAssertNotNil(error, @"collection can't start with $");
    error = nil;
    
    // collection can't be over 256 chars
    NSMutableString *longString = [NSMutableString stringWithCapacity:257];
    for (int i=0; i<257; i++) {
        [longString appendString:@"a"];
    }
    [client addEvent:event toEventCollection:@"$asd" error:&error];
    STAssertNotNil(error, @"collection can't be longer than 256 chars");
}

-(void)testEmptyEventFileUpload {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andWriteKey:@"wk" andReadKey:@"rk"];

    [client addEvent:@{@"fixture key" : @"fixture value"} toEventCollection:@"FixtureCollection" error:nil];
    client.isRunningTests = YES;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *directoryForCollection = [self eventDirectoryForCollection:@"FixtureCollection"];
    NSString *emptyFilePath = [directoryForCollection stringByAppendingPathComponent:@"42"];

    [fileManager createFileAtPath:emptyFilePath contents:[NSData data] attributes:nil];

    [client uploadWithFinishedBlock:nil];

    STAssertFalse([fileManager fileExistsAtPath:emptyFilePath], @"empty event file should be removed");
}

# pragma mark - test filesystem utility methods

- (NSString *)cacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (NSString *)keenDirectory {
    return [[[self cacheDirectory] stringByAppendingPathComponent:@"keen"] stringByAppendingPathComponent:@"id"];
}

- (NSString *)eventDirectoryForCollection:(NSString *)collection {
    return [[self keenDirectory] stringByAppendingPathComponent:collection];
}

- (NSArray *)contentsOfDirectoryForCollection:(NSString *)collection {
    NSString *path = [self eventDirectoryForCollection:collection];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [manager contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        STFail(@"Error when listing contents of directory for collection %@: %@", 
               collection, [error localizedDescription]);
    }
    return contents;
}

- (NSDictionary *)firstEventForCollection:(NSString *)collection {
    NSArray *contents = [self contentsOfDirectoryForCollection:collection];
    NSString *path = [contents objectAtIndex:0];
    NSString *fullPath = [[self eventDirectoryForCollection:collection] stringByAppendingPathComponent:path];
    NSData *data = [NSData dataWithContentsOfFile:fullPath];
    NSDictionary *deserializedDict = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:0
                                                                       error:nil];
    return deserializedDict;
}

@end
