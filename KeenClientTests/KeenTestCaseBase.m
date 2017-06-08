//
//  KeenTestCaseBase.m
//  KeenClient
//
//  Created by Brian Baumhover on 4/27/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <OCMock/OCMock.h>

#import "KIOUtil.h"
#import "KeenClient.h"

#import "KeenClientTestable.h"
#import "KeenTestConstants.h"
#import "KeenClientTestable.h"
#import "KIOUploaderTestable.h"
#import "KIODBStorePrivate.h"
#import "KeenTestUtils.h"
#import "HTTPCodes.h"
#import "TestDatabaseRequirement.h"
#import "KIODBStoreTestable.h"

#import "KeenTestCaseBase.h"

@interface KeenTestCaseBase ()

@property TestDatabaseRequirement *databaseRequirement;

@end

@implementation KeenTestCaseBase

- (void)setUp {
    [super setUp];

    // Acquire a lock on the sqlite store and delete
    // any existing database
    self.databaseRequirement =
        [[TestDatabaseRequirement alloc] initWithDatabasePath:[KIODBStore getSqliteFullFileName]];

    // initialize is called automatically for a class, but
    // call it again to ensure static global state
    // is consistently set to defaults for each test
    // This relies on initialize being idempotent
    [KeenClient initialize];
    [KeenClient enableLogging];
    [KeenClient setLogLevel:KeenLogLevelVerbose];

    // Configure initial state for shared KeenClient instance
    [[KeenClient sharedClient] setCurrentLocation:nil];
    [[KeenClient sharedClient] setGlobalPropertiesBlock:nil];
    [[KeenClient sharedClient] setGlobalPropertiesDictionary:nil];
    [KeenClient sharedClient].config = nil;
}

- (void)tearDown {
    [[KeenClient sharedClient] setCurrentLocation:nil];
    [[KeenClient sharedClient] setGlobalPropertiesBlock:nil];
    [[KeenClient sharedClient] setGlobalPropertiesDictionary:nil];
    [KeenClient sharedClient].config = nil;

    // Delete all file-based collections/events
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[KeenTestUtils keenDirectory]]) {
        [fileManager removeItemAtPath:[KeenTestUtils keenDirectory] error:&error];
        if (error) {
            XCTFail(@"No error should be thrown when cleaning up: %@", [error localizedDescription]);
        }
    }

    // Ensure all db operations have finished
    [[KeenClient sharedClient].store drainQueue];

    // Ensure the sqlite database has been closed since we'll
    // likely be blowing it away and will need to open it again
    [[KeenClient sharedClient].store closeDB];

    // Done with sqlite, free the lock on it
    [self.databaseRequirement unlock];

    [super tearDown];
}

#pragma mark - test mock request methods

- (NSDictionary *)buildResultWithSuccess:(BOOL)success
                            andErrorCode:(NSString *)errorCode
                          andDescription:(NSString *)description {
    NSDictionary *result =
        [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithBool:success] forKey:@"success"];
    if (!success) {
        NSDictionary *error =
            [NSDictionary dictionaryWithObjectsAndKeys:errorCode, @"name", description, @"description", nil];
        [result setValue:error forKey:@"error"];
    }
    return result;
}

- (NSDictionary *)buildResponseJsonWithSuccess:(BOOL)success
                                  AndErrorCode:(NSString *)errorCode
                                AndDescription:(NSString *)description {
    NSDictionary *result = [self buildResultWithSuccess:success andErrorCode:errorCode andDescription:description];
    NSArray *array = [NSArray arrayWithObject:result];
    return [NSDictionary dictionaryWithObject:array forKey:@"foo"];
}

- (id)createClientWithRequestValidator:(BOOL (^)(id obj))validator {
    return [self createClientWithResponseData:nil
                                andStatusCode:HTTPCode200OK
                          andNetworkConnected:@YES
                          andRequestValidator:validator];
}

- (id)createClientWithResponseData:(id)data andStatusCode:(NSInteger)code {
    return [self createClientWithResponseData:data andStatusCode:code andNetworkConnected:@YES];
}

- (id)createClientWithResponseData:(id)data
                     andStatusCode:(NSInteger)code
               andNetworkConnected:(NSNumber *)isNetworkConnected {
    return [self createClientWithResponseData:data
                                andStatusCode:code
                          andNetworkConnected:isNetworkConnected
                          andRequestValidator:nil];
}

- (id)mockUrlSessionWithResponse:(NSHTTPURLResponse *)response
                 andResponseData:(NSData *)responseData
             andRequestValidator:(BOOL (^)(id requestObject))requestValidator {
    // Mock the NSURLSession to be used for the request
    id urlSessionMock = [OCMockObject partialMockForObject:[[NSURLSession alloc] init]];

    // Set up fake response data and request validation
    if (nil != requestValidator) {
        // Set up validation of the request
        [[urlSessionMock expect]
            dataTaskWithRequest:[OCMArg checkWithBlock:requestValidator]
              completionHandler:[OCMArg invokeBlockWithArgs:responseData, response, [NSNull null], nil]];
    } else {
        // We won't check that the request contained anything specific
        [[urlSessionMock stub]
            dataTaskWithRequest:[OCMArg any]
              completionHandler:[OCMArg invokeBlockWithArgs:responseData, response, [NSNull null], nil]];
    }

    return urlSessionMock;
}

- (id)createClientWithResponseData:(id)data
                     andStatusCode:(NSInteger)code
               andNetworkConnected:(NSNumber *)isNetworkConnected
               andRequestValidator:(BOOL (^)(id obj))requestValidator {
    // serialize the faked out response data
    if (!data) {
        data = [self buildResponseJsonWithSuccess:YES AndErrorCode:nil AndDescription:nil];
    }
    data = [KIOUtil handleInvalidJSONInObject:data];
    NSData *serializedData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]
                                                              statusCode:code
                                                             HTTPVersion:nil
                                                            headerFields:nil];

    // Get mock NSURLSession
    id mockSession =
        [self mockUrlSessionWithResponse:response andResponseData:serializedData andRequestValidator:requestValidator];
    
    id mockSessionFactory = OCMProtocolMock(@protocol(KIONSURLSessionFactory));
    OCMStub([mockSessionFactory session]).andReturn(mockSession);
    OCMStub([mockSessionFactory sessionWithConfiguration:[OCMArg any]]).andReturn(mockSession);
    
    // Create/get store
    KIODBStore *store = KIODBStore.sharedInstance;

    // Create network
    KIONetwork *network = [[KIONetwork alloc] initWithURLSessionFactory:mockSessionFactory andStore:store];

    // Create uploader
    KIOUploader *uploader = [[KIOUploader alloc] initWithNetwork:network andStore:store];
    // Mock the KIOUploader to be used for the upload
    id mockUploader = [OCMockObject partialMockForObject:uploader];

    // Mock network status on the KIOUploader object
    [[[mockUploader stub] andReturnValue:isNetworkConnected] isNetworkConnected];

    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey
                                                    andNetwork:network
                                                      andStore:store
                                                   andUploader:mockUploader];

    client.isRunningTests = YES;

    return client;
}

@end
