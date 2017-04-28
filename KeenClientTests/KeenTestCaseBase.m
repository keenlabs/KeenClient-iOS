//
//  KeenTestCaseBase.m
//  KeenClient
//
//  Created by Brian Baumhover on 4/27/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenTestCaseBase.h"
#import "KeenClient.h"
#import "KeenClientTestable.h"
#import "KeenTestUtils.h"


@implementation KeenTestCaseBase


- (void)setUp {
    [super setUp];

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
    // Tear-down code here.
    NSLog(@"\n");
    [[KeenClient sharedClient] clearAllEvents];
    [[KeenClient sharedClient] clearAllQueries];

    [[KeenClient sharedClient] setCurrentLocation:nil];
    [[KeenClient sharedClient] setGlobalPropertiesBlock:nil];
    [[KeenClient sharedClient] setGlobalPropertiesDictionary:nil];
    [KeenClient sharedClient].config = nil;

    // delete all collections and their events.
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[KeenTestUtils keenDirectory]]) {
        [fileManager removeItemAtPath:[KeenTestUtils keenDirectory] error:&error];
        if (error) {
            XCTFail(@"No error should be thrown when cleaning up: %@", [error localizedDescription]);
        }
    }
    [super tearDown];
}


@end
