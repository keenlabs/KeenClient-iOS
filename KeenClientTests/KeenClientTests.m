//
//  KeenClientTests.m
//  KeenClientTests
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenClientTests.h"
#import "KeenClient.h"
#import "CJSONDeserializer.h"
#import "CJSONSerializer.h"
#import <OCMock/OCMock.h>


@interface KeenClientTests () {}

- (NSString *) getCacheDirectory;
- (NSString *) getKeenDirectory;
- (NSString *) getEventDirectoryForCollection: (NSString *) collection;
- (NSArray *) contentsOfDirectoryForCollection: (NSString *) collection;

@end

@implementation KeenClientTests

- (void) setUp {
    [super setUp];
    
    // Set-up code here.
}

- (void) tearDown {
    // Tear-down code here.
    
    // delete all collections and their events.
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[self getKeenDirectory]]) {
        [fileManager removeItemAtPath:[self getKeenDirectory] error:&error];
        if (error) {
            STFail(@"No error should be thrown when cleaning up: %@", [error localizedDescription]);
        }
    }
    
    [super tearDown];
}

- (void) testGetClientForAuthToken {
    KeenClient *client = [KeenClient clientForProject:@"id" WithAuthToken:@"auth"];
    STAssertNotNil(client, @"Expected getClient with non-nil token to return non-nil client.");
    
    KeenClient *client2 = [KeenClient clientForProject:@"id" WithAuthToken:@"auth"];
    STAssertEqualObjects(client, client2, @"getClient on the same token twice should return the same instance twice.");
    
    client = [KeenClient clientForProject:@"id" WithAuthToken:nil];
    STAssertNil(client, @"Expected getClient with nil token to return nil client.");
    
    client = [KeenClient clientForProject:@"id" WithAuthToken:@"some_other_token"];
    STAssertFalse(client == client2, @"getClient on two different tokens should return two difference instances.");
}

- (void) testAddEvent {
    KeenClient *client = [KeenClient clientForProject:@"id" WithAuthToken:@"auth"];
    
    // nil dict should should do nothing
    Boolean response = [client addEvent:nil ToCollection:@"foo"];
    STAssertFalse(response, @"nil dict should return NO");
    
    // nil collection should do nothing
    response = [client addEvent:[NSDictionary dictionary] ToCollection:nil];
    STAssertFalse(response, @"nil collection should return NO");
    
    // basic dict should work
    NSArray *keys = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
    NSArray *values = [NSArray arrayWithObjects:@"apple", @"bapple", @"capple", nil];
    NSDictionary *event = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    response = [client addEvent:event ToCollection:@"foo"];
    STAssertTrue(response, @"an okay event should return YES");
    // now go find the file we wrote to disk
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    NSString *path = [contents objectAtIndex:0];
    NSString *fullPath = [[self getEventDirectoryForCollection:@"foo"] stringByAppendingPathComponent:path];
    NSData *data = [NSData dataWithContentsOfFile:fullPath];
    NSError *error = nil;
    NSDictionary *deserializedDict = [[CJSONDeserializer deserializer] deserialize:data error:&error];
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
    response = [client addEvent:event ToCollection:@"foo"];
    STAssertTrue(response, @"an event with a date should return YES"); 
    
    // now there should be two files
    contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 2, @"There should be two files written.");
    
    // dict with non-serializable value should do nothing
    keys = [NSArray arrayWithObjects:@"a", @"b", @"bad_key", nil];
    NSError *badValue = [[NSError alloc] init];
    values = [NSArray arrayWithObjects:@"apple", @"bapple", badValue, nil];
    event = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    response = [client addEvent:event ToCollection:@"foo"];
    STAssertFalse(response, @"an event that can't be serialized should return NO");
}

- (NSData *) sendEvents: (NSData *) data returningResponse: (NSURLResponse **) response error: (NSError **) error {
    // for some reason without this method, testUpload has compile warnings. this should never actually be invoked.
    // pretty annoying.
    return nil;
}

- (NSDictionary *) buildResultWithSuccess: (Boolean) success 
                             AndErrorCode: (NSString *) errorCode 
                           AndDescription: (NSString *) description {
    NSDictionary *result = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithBool:success]
                                                              forKey:@"success"];
    if (!success) {
        [result setValue:errorCode forKey:@"name"];
        [result setValue:description forKey:@"description"];
    }
    return result;
}

- (NSDictionary *) buildResponseJsonWithSuccess: (Boolean) success 
                                   AndErrorCode: (NSString *) errorCode 
                                 AndDescription: (NSString *) description {
    NSDictionary *result = [self buildResultWithSuccess:success 
                                           AndErrorCode:errorCode 
                                         AndDescription:description];
    NSArray *array = [NSArray arrayWithObject:result];
    return [NSDictionary dictionaryWithObject:array forKey:@"foo"];
}

- (id) uploadTestHelperWithData: (id) data AndStatusCode: (NSInteger) code {
    if (!data) {
        data = [self buildResponseJsonWithSuccess:YES AndErrorCode:nil AndDescription:nil];
    }
    
    // set up the partial mock
    KeenClient *client = [KeenClient clientForProject:@"id" WithAuthToken:@"auth"];
    id mock = [OCMockObject partialMockForObject:client];
    
    // set up the response we're faking out
    NSHTTPURLResponse *response = [[[NSHTTPURLResponse alloc] initWithURL:nil statusCode:code HTTPVersion:nil headerFields:nil] autorelease];
    
    // serialize the faked out response data
    NSData *serializedData = [[CJSONSerializer serializer] serializeObject:data error:nil];
    NSString *json = [[NSString alloc] initWithData:serializedData encoding:NSUTF8StringEncoding];
    NSLog(@"created json: %@", json);
    [json release];
    
    // set up the response data we're faking out
    [[[mock stub] andReturn:serializedData] sendEvents:[OCMArg any] 
                                     returningResponse:[OCMArg setTo:response] 
                                                 error:[OCMArg setTo:nil]];
    
    return mock;
}

- (void) addSimpleEventAndUploadWithMock: (id) mock {
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] ToCollection:@"foo"];
    
    // and "upload" it
    [mock upload];
}

- (void) testUploadSuccess {
    id mock = [self uploadTestHelperWithData:nil AndStatusCode:200];
    
    [self addSimpleEventAndUploadWithMock:mock];
    
    // make sure the file was deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
}

- (void) testUploadFailedServerDown {
    id mock = [self uploadTestHelperWithData:@"" AndStatusCode:500];
    
    [self addSimpleEventAndUploadWithMock:mock];
    
    // make sure the file wasn't deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 1, @"There should be one file after a failed upload.");    
}

- (void) testUploadFailedServerDownNonJsonResponse {
    id mock = [self uploadTestHelperWithData:@"bad data" AndStatusCode:500];
    
    [self addSimpleEventAndUploadWithMock:mock];
    
    // make sure the file wasnt't deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 1, @"There should be one file after a failed upload.");    
}

- (void) testUploadFailedBadRequest {
    id mock = [self uploadTestHelperWithData:[self buildResponseJsonWithSuccess:NO 
                                                                   AndErrorCode:@"InvalidCollectionNameError" 
                                                                 AndDescription:@"anything"] 
                               AndStatusCode:200];
    
    [self addSimpleEventAndUploadWithMock:mock];
    
    // make sure the file was deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 0, @"An invalid event should be deleted after an upload attempt.");
}

- (void) testUploadFailedBadRequestUnknownError {
    id mock = [self uploadTestHelperWithData:@"doesn't matter" AndStatusCode:400];
    
    [self addSimpleEventAndUploadWithMock:mock];
    
    // make sure the file was deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 1, @"An upload that results in an unexpected error should not delete the event.");     
}

- (void) testUploadMultipleEventsSameCollectionSuccess {
    NSDictionary *result1 = [self buildResultWithSuccess:YES 
                                            AndErrorCode:nil 
                                          AndDescription:nil];
    NSDictionary *result2 = [self buildResultWithSuccess:NO
                                            AndErrorCode:@"InvalidCollectionNameError" 
                                          AndDescription:@"something"];
    NSDictionary *result = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:result1, result2, nil]
                                                       forKey:@"foo"];
    id mock = [self uploadTestHelperWithData:result AndStatusCode:200];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] ToCollection:@"foo"];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple2" forKey:@"a"] ToCollection:@"foo"];
    
    // and "upload" it
    [mock upload];
    
    // make sure the file were deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
}

- (void) testUploadMultipleEventsDifferentCollectionSuccess {
    NSDictionary *result1 = [self buildResultWithSuccess:YES 
                                            AndErrorCode:nil 
                                          AndDescription:nil];
    NSDictionary *result2 = [self buildResultWithSuccess:NO
                                            AndErrorCode:@"InvalidCollectionNameError" 
                                          AndDescription:@"something"];
    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSArray arrayWithObject:result1], @"foo", 
                            [NSArray arrayWithObject:result2], @"bar", nil];
    id mock = [self uploadTestHelperWithData:result AndStatusCode:200];
    
    // add an event
    [mock addEvent:[NSDictionary dictionaryWithObject:@"apple" forKey:@"a"] ToCollection:@"foo"];
    [mock addEvent:[NSDictionary dictionaryWithObject:@"bapple" forKey:@"b"] ToCollection:@"bar"];
    
    // and "upload" it
    [mock upload];
    
    // make sure the files were deleted locally
    NSArray *contents = [self contentsOfDirectoryForCollection:@"foo"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
    contents = [self contentsOfDirectoryForCollection:@"bar"];
    STAssertTrue([contents count] == 0, @"There should be no files after a successful upload.");
}

- (void) testUploadMultipleEventsSameCollectionOneFails {
}

- (void) testUploadMultipleEventsDifferentCollectionsOneFails {
}

- (NSString *) getCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (NSString *) getKeenDirectory {
    return [[self getCacheDirectory] stringByAppendingPathComponent:@"keen"];
}

- (NSString *) getEventDirectoryForCollection: (NSString *) collection {
    // TODO parameterize the project ID here?
    NSString *projectDir = [[self getKeenDirectory] stringByAppendingPathComponent:@"id"];
    return [projectDir stringByAppendingPathComponent:collection];
}

- (NSArray *) contentsOfDirectoryForCollection: (NSString *) collection {
    NSString *path = [self getEventDirectoryForCollection:collection];
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
