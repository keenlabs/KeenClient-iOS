//
//  TestDatabaseRequirement.h
//  KeenClient
//
//  Created by Brian Baumhover on 5/8/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "TestDatabaseRequirement.h"
#import "KeenTestUtils.h"

@implementation TestDatabaseRequirement

+ (NSLock *)sharedLock {
    static NSLock *s_sharedLock = nil;

    // This black magic ensures this block
    // is dispatched only once over the lifetime
    // of the program. It's nice because
    // this works even when there's a race
    // between threads to create the object,
    // as both threads will wait synchronously
    // for the block to complete.
    static dispatch_once_t predicate = {0};
    dispatch_once(&predicate, ^{
        s_sharedLock = [[NSLock alloc] init];
    });

    return s_sharedLock;
}

- (instancetype)init {
    [NSException raise:@"Not Implemented" format:@"Not Implemented"];
    return nil;
}

- (instancetype)initWithDatabasePath:(NSString *)path {
    self = [super init];
    if (nil != self) {
        // Acquire the lock and then delete the database
        [self lockAndCleanDatabase:path];
    }
    return self;
}

- (void)lockAndCleanDatabase:(NSString *)databasePath {
    [[self.class sharedLock] lock];

    // Blow away any existing database so we start fresh
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:databasePath]) {
        if ([fileManager removeItemAtPath:databasePath error:NULL] == YES) {
            NSLog(@"Removed database file.");
        } else {
            NSLog(@"Failed to remove database file.");
        }
    }
}

- (void)unlock {
    [[self.class sharedLock] unlock];
}

- (void)dealloc {
    [self unlock];
}

@end
