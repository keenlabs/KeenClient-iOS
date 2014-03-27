//
//  EventStoreTests.m
//  KeenClient
//
//  Created by Cory Watson on 3/26/14.
//  Copyright (c) 2014 Keen Labs. All rights reserved.
//

#import "EventStore.h"
#import "EventStoreTests.h"

@interface EventStoreTests ()

- (NSString *)cacheDirectory;
- (NSString *)keenDirectory;
- (NSString *)eventDirectoryForCollection:(NSString *)collection;
- (NSArray *)contentsOfDirectoryForCollection:(NSString *)collection;
- (NSDictionary *)firstEventForCollection:(NSString *)collection;

@end

@implementation EventStoreTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Tear-down code here.
    NSLog(@"\n");

    [super tearDown];
}

- (void)testInit{
    EventStore *store = [[EventStore alloc] init];
}

@end
