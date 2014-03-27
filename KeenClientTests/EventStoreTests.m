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

- (NSString *)databaseFile;

@end

@implementation EventStoreTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Tear-down code here.
    NSLog(@"\n");

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager removeItemAtPath:[self databaseFile] error:NULL] == YES) {
        NSLog(@"Removed database file.");
    } else {
        NSLog(@"Failed to remove database file.");
    }

    [super tearDown];
}

- (void)testInit{
    EventStore *store = [[EventStore alloc] init];
    STAssertNotNil(store, @"init is not null");
    NSString *dbPath = [self databaseFile];
    NSLog(dbPath);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSAssert([fileManager fileExistsAtPath:dbPath], @"Database file exists.");
}

- (NSString *)databaseFile {
    NSString *databasePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [databasePath stringByAppendingPathComponent:@"keenEvents.sqlite"];
}



@end
