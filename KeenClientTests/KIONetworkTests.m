//
//  KIONetworkTests.m
//  KeenClient
//
//  Created by Brian Baumhover on 6/14/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "KIONetworkTests.h"
#import "KeenConstants.h"
#import "KeenTestConstants.h"
#import "KeenClient.h"
#import "KIONSURLSessionFactory.h"
#import "KIODBStore.h"
#import "KIONetwork.h"

@implementation KIONetworkTests

- (void)testDefaultApiUrlAuthority {
    // Test default authority
    [self doApiUrlAuthorityTest:nil expectedApiUrlAuthority:kKeenDefaultApiUrlAuthority];
}

- (void)testCustomApiUrlAuthority {
    // Test default authority
    [self doApiUrlAuthorityTest:@"some.other.authority:890" expectedApiUrlAuthority:@"some.other.authority:890"];
}

- (void)doApiUrlAuthorityTest:(NSString *)apiUrlAuthority expectedApiUrlAuthority:(NSString *)expectedApiUrlAuthority {
    NSData *eventJsonData = [@"{\"event\":\"data\"}" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *expectedProjectEventUrl =
    [NSString stringWithFormat:@"https://%@/3.0/projects/%@/events", expectedApiUrlAuthority, kDefaultProjectID];
    
    // Create a mock session and use it to verify the request url
    NSURLSession *mockSession = OCMClassMock([NSURLSession class]);
    
    XCTestExpectation *requestMade = [self expectationWithDescription:@"Should make an upload request"];
    OCMStub([mockSession
             dataTaskWithRequest:[OCMArg any]
             completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null], [NSNull null], [NSNull null], nil])])
    .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSURLRequest *request;   // Don't release because getArgument doesn't retain
        [invocation getArgument:&request atIndex:2]; // Get first argument, 0 is self and 1 is the selector
        
        // Verify the request URL
        XCTAssertEqualObjects(expectedProjectEventUrl, request.URL.absoluteString);
        [requestMade fulfill];
    });
    
    id<KIONSURLSessionFactory> sessionFactory = OCMProtocolMock(@protocol(KIONSURLSessionFactory));
    OCMStub([sessionFactory session]).andReturn(mockSession);
    
    KIODBStore *mockStore = OCMClassMock([KIODBStore class]);
    
    KIONetwork *network = [[KIONetwork alloc] initWithURLSessionFactory:sessionFactory andStore:mockStore];
    
    // Create a config that will use the default API URL authority
    KeenClientConfig *config;
    if (nil != apiUrlAuthority) {
        config = [[KeenClientConfig alloc] initWithProjectID:kDefaultProjectID
                                                 andWriteKey:kDefaultWriteKey
                                                  andReadKey:kDefaultReadKey
                                             apiUrlAuthority:apiUrlAuthority];
        
    } else {
        config = [[KeenClientConfig alloc] initWithProjectID:kDefaultProjectID
                                                 andWriteKey:kDefaultWriteKey
                                                  andReadKey:kDefaultReadKey];
    }
    
    // Make an upload request
    XCTestExpectation *eventsUploaded = [self expectationWithDescription:@"Events should upload."];
    [network sendEvents:eventJsonData
                 config:config
      completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
          [eventsUploaded fulfill];
      }];
    
    [self waitForExpectationsWithTimeout:kTestExpectationTimeoutInterval handler:nil];
}

@end
