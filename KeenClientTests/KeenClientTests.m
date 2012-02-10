//
//  KeenClientTests.m
//  KeenClientTests
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenClientTests.h"
#import "KeenClient.h"


@implementation KeenClientTests

- (void) setUp {
    [super setUp];
    
    // Set-up code here.
}

- (void) tearDown {
    // Tear-down code here.
    
    [super tearDown];
}

- (void) testGetClientForAuthToken {
    KeenClient *client = [KeenClient getClientForAuthToken:@"some_token"];
    STAssertNotNil(client, @"Expected getClient with non-nil token to return non-nil client.");
    
    client = [KeenClient getClientForAuthToken:nil];
    STAssertNil(client, @"Expected getClient with nil token to return nil client.");
}

@end
