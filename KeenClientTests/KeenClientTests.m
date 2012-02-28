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
#import "JSONKit.h"
#import "KeenConstants.h"


@interface KeenClient (testability)

// The project ID for this particular client.
@property (nonatomic, retain) NSString *projectId;

// The authorization token for this particular project.
@property (nonatomic, retain) NSString *token;

// If we're running tests.
@property (nonatomic) Boolean isRunningTests;

- (NSData *)sendEvents: (NSData *) data returningResponse: (NSURLResponse **) response error: (NSError **) error;

@end

@interface KeenClientTests ()

- (NSString *)cacheDirectory;
- (NSString *)keenDirectory;
- (NSString *)eventDirectoryForCollection:(NSString *)collection;
- (NSArray *)contentsOfDirectoryForCollection:(NSString *)collection;

@end

@implementation KeenClientTests

- (void)setUp {
    [super setUp];
    
    // Set-up code here.
    [[KeenClient sharedClient] setProjectId:nil];
    [[KeenClient sharedClient] setToken:nil];
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

- (void)testInitWithProjectIdAndAuthToken{
    KeenClient *client = [[KeenClient alloc] initWithProjectId:@"something" andAuthToken:@"anything"];
    STAssertEqualObjects(@"something", client.projectId, @"init with a valid project ID should work");
    STAssertEqualObjects(@"anything", client.token, @"init with a valid token should work");
    
    KeenClient *client2 = [[KeenClient alloc] initWithProjectId:@"another" andAuthToken:@"again"];
    STAssertTrue(client != client2, @"Another init should return a separate instance");
    
    [client release];
    [client2 release];
    
    client = [[KeenClient alloc] initWithProjectId:nil andAuthToken:@"valid"];
    STAssertNil(client, @"init with a nil project ID should return nil");
    
    client = [[KeenClient alloc] initWithProjectId:@"valid" andAuthToken:nil];
    STAssertNil(client, @"init with a nil auth token should return nil");
}

- (void)testSharedClientWithProjectIdAndAuthToken{
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andAuthToken:@"auth"];
    STAssertEquals(@"id", client.projectId, 
                   @"sharedClientWithProjectIdAndAuthToken with a non-nil project ID should work.");
    STAssertEquals(@"auth", client.token, 
                   @"sharedClientWithProjectIdAndAuthToken with a non-nil token should work");
    
    KeenClient *client2 = [KeenClient sharedClientWithProjectId:@"other" andAuthToken:@"another"];
    STAssertEqualObjects(client, client2, @"sharedClient should return the same instance");
    
    client = [KeenClient sharedClientWithProjectId:nil andAuthToken:@"valid"];
    STAssertNil(client, @"sharedClient with an invalid project ID should return nil");
    
    client = [KeenClient sharedClientWithProjectId:@"valid" andAuthToken:nil];
    STAssertNil(client, @"sharedClient with an invalid auth token should return nil");
}

- (void)testSharedClient {
    KeenClient *client = [KeenClient sharedClient];
    STAssertNil(client.projectId, @"a client's project ID should be nil at first");
    STAssertNil(client.token, @"a client's token should be nil at first");
    
    KeenClient *client2 = [KeenClient sharedClient];
    STAssertEqualObjects(client, client2, @"sharedClient should return the same instance");
}

- (void)testAddEvent {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andAuthToken:@"auth"];
    
    // nil dict should should do nothing
    Boolean response = [client addEvent:nil toCollection:@"foo"];
    STAssertFalse(response, @"nil dict should return NO");
    
    // nil collection should do nothing
    response = [client addEvent:[NSDictionary dictionary] toCollection:nil];
    STAssertFalse(response, @"nil collection should return NO");
    
    // basic dict should work
    NSArray *keys = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    NSArray *values = [NSArray arrayWithObjects:@"apple", @"bapple", @"capple", nil];
    NSDictionary *event = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    response = [client addEvent:event toCollection:@"foo"];
    STAssertTrue(response, @"an okay event should return YES");
    // now go find the file we wrote to disk
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    NSString *path = [contents objectAtIndex:0];
    NSString *fullPath = [[self eventDirectoryForCollection:@"foo"] stringByAppendingPathComponent:path];
    NSData *data = [NSData dataWithContentsOfFile:fullPath];
    NSDictionary *deserializedDict = [data objectFromJSONData];
    // make sure timestamp was added
    STAssertNotNil(deserializedDict, @"The event should have been written to disk.");
    STAssertNotNil([deserializedDict objectForKey:@"timestamp"], @"The event written to disk should have had a timestamp added: %@", deserializedDict);
    STAssertEqualObjects(@"apple", [deserializedDict objectForKey:@"a"], @"Value for key 'a' is wrong.");
    STAssertEqualObjects(@"bapple", [deserializedDict objectForKey:@"b"], @"Value for key 'b' is wrong.");
    STAssertEqualObjects(@"capple", [deserializedDict objectForKey:@"c"], @"Value for key 'c' is wrong.");
    
    // dict with NSDate should work
    keys = [NSArray arrayWithObjects:@"a", @"b", @"a_date", nil];
    values = [NSArray arrayWithObjects:@"apple", @"bapple", [NSDate date], nil];
    event = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    response = [client addEvent:event toCollection:@"foo"];
    STAssertTrue(response, @"an event with a date should return YES"); 
    
    // now there should be two files
    contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 2, @"There should be two files written.");
    
    // dict with non-serializable value should do nothing
    keys = [NSArray arrayWithObjects:@"a", @"b", @"bad_key", nil];
    NSError *badValue = [[NSError alloc] init];
    values = [NSArray arrayWithObjects:@"apple", @"bapple", badValue, nil];
    event = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    response = [client addEvent:event toCollection:@"foo"];
    STAssertFalse(response, @"an event that can't be serialized should return NO");
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
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andAuthToken:@"auth"];
    client.isRunningTests = YES;
    id mock = [OCMockObject partialMockForObject:client];
    
    // set up the response we're faking out
    NSHTTPURLResponse *response = [[[NSHTTPURLResponse alloc] initWithURL:nil statusCode:code HTTPVersion:nil headerFields:nil] autorelease];
    
    // serialize the faked out response data
    NSData *serializedData = [data JSONData];
    NSString *json = [[NSString alloc] initWithData:serializedData encoding:NSUTF8StringEncoding];
    NSLog(@"created json: %@", json);
    [json release];
    
    // set up the response data we're faking out
    [[[mock stub] andReturn:serializedData] sendEvents:[OCMArg any] 
                                     returningResponse:[OCMArg setTo:response] 
                                                 error:[OCMArg setTo:nil]];
    
    return mock;
}

- (void)addSimpleEventAndUploadWithMock:(id)mock {
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toCollection:@"foo"];
    
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
    id mock = [self uploadTestHelperWithData:@"" andStatusCode:500];
    
    [self addSimpleEventAndUploadWithMock:mock];
    
    // make sure the file wasn't deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 1, @"There should be one file after a failed upload.");    
}

- (void)testUploadFailedServerDownNonJsonResponse {
    id mock = [self uploadTestHelperWithData:@"bad data" andStatusCode:500];
    
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
    id mock = [self uploadTestHelperWithData:@"doesn't matter" andStatusCode:400];
    
    [self addSimpleEventAndUploadWithMock:mock];
    
    // make sure the file was deleted locally
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
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toCollection:@"foo"];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple2" forKey:@"a"] toCollection:@"foo"];
    
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
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toCollection:@"foo"];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] toCollection:@"bar"];
    
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
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toCollection:@"foo"];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple2" forKey:@"a"] toCollection:@"foo"];
    
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
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toCollection:@"foo"];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] toCollection:@"bar"];
    
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
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] toCollection:@"foo"];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] toCollection:@"bar"];
    
    // and "upload" it
    [mock uploadWithFinishedBlock:nil];
    
    // make sure the files were deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
    contents = [self contentsOfDirectoryForCollection:@"bar"];
    STAssertTrue([contents count] == 1, @"There should be a file after a failed upload.");
}

- (void)testTooManyEventsCached {
    KeenClient *client = [KeenClient sharedClientWithProjectId:@"id" andAuthToken:@"auth"];
    client.isRunningTests = YES;
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:@"bar", @"foo", nil];
    // create 5 events
    for (int i=0; i<5; i++) {
        [client addEvent:event toCollection:@"something"];
        NSLog(@"Added event %d", i);
    }
    // should be 5 events now
    NSArray *contentsBefore = [self contentsOfDirectoryForCollection:@"something"];
    STAssertTrue([contentsBefore count] == 5, @"There should be exactly five events.");
    // now do one more, should age out 2 old ones
    [client addEvent:event toCollection:@"something"];
    // so now there should be 4 left (5 - 2 + 1)
    NSArray *contentsAfter = [self contentsOfDirectoryForCollection:@"something"];
    STAssertTrue([contentsAfter count] == 4, @"There should be exactly four events.");
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
    NSLog(@"path: %@", path);
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [manager contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        STFail(@"Error when listing contents of directory for collection %@: %@", 
               collection, [error localizedDescription]);
    }
    return contents;
}

@end
