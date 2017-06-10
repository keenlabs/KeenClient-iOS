//
//  KeenClientTests.m
//  KeenClientTests
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenClientTests.h"
#import "KeenClient.h"
#import "KeenClientConfig.h"
#import <OCMock/OCMock.h>
#import "KeenConstants.h"
#import "KeenProperties.h"
#import "HTTPCodes.h"
#import "KIOUtil.h"
#import "KIOQuery.h"
#import "KIOFileStore.h"
#import "KIONetwork.h"
#import "KIOUploader.h"

#import "KeenTestUtils.h"
#import "KeenTestConstants.h"
#import "KeenClientTestable.h"
#import "KIONetworkTestable.h"
#import "KIOUploaderTestable.h"

@implementation KeenClientTests

- (void)testInitWithProjectID {
    KeenClient *client =
        [[KeenClient alloc] initWithProjectID:@"something" andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    XCTAssertEqualObjects(@"something", client.config.projectID, @"init with a valid project id should work");
    XCTAssertEqualObjects(kDefaultWriteKey, client.config.writeKey, @"init with a valid project id should work");
    XCTAssertEqualObjects(kDefaultReadKey, client.config.readKey, @"init with a valid project id should work");

    KeenClient *client2 = [[KeenClient alloc] initWithProjectID:@"another" andWriteKey:@"wk2" andReadKey:@"rk2"];
    XCTAssertEqualObjects(@"another", client2.config.projectID, @"init with a valid project id should work");
    XCTAssertEqualObjects(@"wk2", client2.config.writeKey, @"init with a valid project id should work");
    XCTAssertEqualObjects(@"rk2", client2.config.readKey, @"init with a valid project id should work");
    XCTAssertTrue(client != client2, @"Another init should return a separate instance");

    client = [[KeenClient alloc] initWithProjectID:nil andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    XCTAssertNil(client, @"init with a nil project ID should return nil");
}

- (void)testInstanceClient {
    KeenClient *client = [[KeenClient alloc] init];
    XCTAssertNil(client.config.projectID, @"a client's project id should be nil at first");
    XCTAssertNil(client.config.writeKey, @"a client's write key should be nil at first");
    XCTAssertNil(client.config.readKey, @"a client's read key should be nil at first");

    KeenClient *client2 = [[KeenClient alloc] init];
    XCTAssertTrue(client != client2, @"Another init should return a separate instance");
}

- (void)testSharedClientWithProjectID {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    XCTAssertEqual(kDefaultProjectID,
                   client.config.projectID,
                   @"sharedClientWithProjectID with a non-nil project id should work.");
    XCTAssertEqualObjects(kDefaultWriteKey, client.config.writeKey, @"init with a valid project id should work");
    XCTAssertEqualObjects(kDefaultReadKey, client.config.readKey, @"init with a valid project id should work");

    KeenClient *client2 = [KeenClient sharedClientWithProjectID:@"other" andWriteKey:@"wk2" andReadKey:@"rk2"];
    XCTAssertEqualObjects(client, client2, @"sharedClient should return the same instance");
    XCTAssertEqualObjects(kDefaultWriteKey, client2.config.writeKey, @"sharedClient should not change the writeKey after first init.");
    XCTAssertEqualObjects(kDefaultReadKey, client2.config.readKey, @"sharedClient should not change the readKey after first init.");

    client = [KeenClient sharedClientWithProjectID:nil andWriteKey:kDefaultWriteKey andReadKey:kDefaultReadKey];
    XCTAssertNil(client, @"sharedClient with an invalid project id should return nil");
}

- (void)testSharedClient {
    KeenClient *client = [KeenClient sharedClient];
    XCTAssertNil(client.config.projectID, @"a client's project id should be nil at first");
    XCTAssertNil(client.config.writeKey, @"a client's write key should be nil at first");
    XCTAssertNil(client.config.readKey, @"a client's read key should be nil at first");

    KeenClient *client2 = [KeenClient sharedClient];
    XCTAssertEqualObjects(client, client2, @"sharedClient should return the same instance");
}

- (void)testBasicAddon {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    KeenClient *clientI = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                    andWriteKey:kDefaultWriteKey
                                                     andReadKey:kDefaultReadKey];

    NSDictionary *theEvent = @{
        @"keen": @{
            @"addons": @[@{
                @"name": @"addon:name",
                @"input": @{@"param_name": @"property_that_contains_param"},
                @"output": @"property.to.store.output"
            }]
        },
        @"a": @"b"
    };

    // add the event
    NSError *error = nil;
    [client addEvent:theEvent toEventCollection:@"foo" error:&error];
    [clientI addEvent:theEvent toEventCollection:@"foo" error:&error];
    XCTAssertNil(error, @"event should add");

    // Grab the first event we get back
    NSDictionary *eventsForCollection =
        [[KIODBStore.sharedInstance getEventsWithMaxAttempts:3 andProjectID:client.config.projectID]
            objectForKey:@"foo"];
    // Grab the first event we get back
    NSData *eventData = [eventsForCollection objectForKey:[[eventsForCollection allKeys] objectAtIndex:0]];
    NSDictionary *deserializedDict = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:&error];

    NSDictionary *deserializedAddon = deserializedDict[@"keen"][@"addons"][0];
    XCTAssertEqualObjects(@"addon:name", deserializedAddon[@"name"], @"Addon name should be right");
}

- (void)testSDKVersion {
    KeenClient *client = [KeenClient sharedClientWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    // result from class method should equal the SDK Version constant
    XCTAssertTrue([[KeenClient sdkVersion] isEqual:kKeenSdkVersion],
                  @"SDK Version from class method equals the SDK Version constant.");
    XCTAssertFalse(![[KeenClient sdkVersion] isEqual:kKeenSdkVersion],
                   @"SDK Version from class method doesn't equal the SDK Version constant.");
}

- (void)testSDKVersionInstanceClient {
    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey];
    client.isRunningTests = YES;

    // result from class method should equal the SDK Version constant
    XCTAssertTrue([[KeenClient sdkVersion] isEqual:kKeenSdkVersion],
                  @"SDK Version from class method equals the SDK Version constant.");
    XCTAssertFalse(![[KeenClient sdkVersion] isEqual:kKeenSdkVersion],
                   @"SDK Version from class method doesn't equal the SDK Version constant.");
}

- (void)testProxy {
    NSString *proxyHost = @"127.0.0.1";
    NSNumber *proxyPort = @(8888);

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]
                                                              statusCode:HTTPCode200OK
                                                             HTTPVersion:nil
                                                            headerFields:nil];
    NSData *responseData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSession *session =
        [self mockUrlSessionWithResponse:response andResponseData:responseData andRequestValidator:nil];

    KIODBStore *store = [[KIODBStore alloc] init];

    // Build a session configuration as expected with the enabled proxy
    NSURLSessionConfiguration *expectedConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    expectedConfiguration.connectionProxyDictionary = @{
        @"HTTPEnable": @(YES),
        (NSString *)kCFStreamPropertyHTTPProxyHost: proxyHost,
        (NSString *)kCFStreamPropertyHTTPProxyPort: proxyPort,
        @"HTTPSEnable": @(YES),
        (NSString *)kCFStreamPropertyHTTPSProxyHost: proxyHost,
        (NSString *)kCFStreamPropertyHTTPSProxyPort: proxyPort,
    };

    // Expect the correct configuration to be called
    id mockSessionFactory = [OCMockObject mockForProtocol:@protocol(KIONSURLSessionFactory)];

    [[[mockSessionFactory expect] andReturn:session]
        sessionWithConfiguration:[OCMArg checkWithBlock:^BOOL(NSURLSessionConfiguration *configuration) {
            XCTAssertEqualObjects(configuration.connectionProxyDictionary,
                                  expectedConfiguration.connectionProxyDictionary);
            return @(YES);
        }]];

    KIONetwork *network = [[KIONetwork alloc] initWithURLSessionFactory:mockSessionFactory andStore:store];

    KIOUploader *uploader = [[KIOUploader alloc] initWithNetwork:network andStore:store];

    KeenClient *client = [[KeenClient alloc] initWithProjectID:kDefaultProjectID
                                                   andWriteKey:kDefaultWriteKey
                                                    andReadKey:kDefaultReadKey
                                                    andNetwork:network
                                                      andStore:store
                                                   andUploader:uploader];

    BOOL success = [client setProxy:proxyHost port:proxyPort];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(client.proxyHost, proxyHost);
    XCTAssertEqualObjects(client.proxyPort, proxyPort);

    // Add an event and upload it
    NSError *error;
    [client addEvent:@{ @"some_key": @"some_value" } toEventCollection:@"collection" error:&error];
    XCTAssertNil(error);

    XCTestExpectation *uploadFinished = [self expectationWithDescription:@"upload finished"];
    [client uploadWithFinishedBlock:^{
        [uploadFinished fulfill];
    }];

    // Wait for the upload to complete, with mock validating configuration parameter
    [self waitForExpectations:@[uploadFinished] timeout:kTestExpectationTimeoutInterval];

    success = [client setProxy:nil port:nil];
    XCTAssertTrue(success);
    XCTAssertNil(client.proxyHost);
    XCTAssertNil(client.proxyPort);

    // Expect another call, but this time for the default session since no proxy is set
    [[[mockSessionFactory expect] andReturn:session] session];
    // Add an event and upload it
    [client addEvent:@{ @"some_second_key": @"some_second_value" } toEventCollection:@"second_collection" error:&error];
    XCTAssertNil(error);

    XCTestExpectation *secondUploadFinished = [self expectationWithDescription:@"second upload finished"];
    [client uploadWithFinishedBlock:^{
        [secondUploadFinished fulfill];
    }];

    // Wait for the upload to complete, with mock validating configuration parameter
    [self waitForExpectations:@[secondUploadFinished] timeout:kTestExpectationTimeoutInterval];

    success = [client setProxy:proxyHost port:nil];
    XCTAssertFalse(success);
    XCTAssertNil(client.proxyHost);
    XCTAssertNil(client.proxyPort);

    success = [client setProxy:nil port:proxyPort];
    XCTAssertFalse(success);
    XCTAssertNil(client.proxyHost);
    XCTAssertNil(client.proxyPort);

    // Ensure all expected calls were made
    [mockSessionFactory verify];
}

@end
