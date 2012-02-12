//
//  KeenClientTests.m
//  KeenClientTests
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenClientTests.h"
#import "KeenClient.h"


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
    KeenClient *client = [KeenClient getClientForAuthToken:@"some_token"];
    STAssertNotNil(client, @"Expected getClient with non-nil token to return non-nil client.");
    
    KeenClient *client2 = [KeenClient getClientForAuthToken:@"some_token"];
    STAssertEqualObjects(client, client2, @"getClient on the same token twice should return the same instance twice.");
        
    client = [KeenClient getClientForAuthToken:nil];
    STAssertNil(client, @"Expected getClient with nil token to return nil client.");
    
    client = [KeenClient getClientForAuthToken:@"some_other_token"];
    STAssertFalse(client == client2, @"getClient on two different tokens should return two difference instances.");
}

- (void) testAddEvent {
    KeenClient *client = [KeenClient getClientForAuthToken:@"a"];
    
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
    NSDictionary *deserializedDict = [NSDictionary dictionaryWithContentsOfFile:fullPath];
    // make sure timestamp was added
    STAssertNotNil(deserializedDict, @"The event should have been written to disk.");
    STAssertNotNil([deserializedDict objectForKey:@"timestamp"], @"The event written to disk should have had a timestamp added.");
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

- (NSString *) getCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (NSString *) getKeenDirectory {
    return [[self getCacheDirectory] stringByAppendingPathComponent:@"keen"];
}

- (NSString *) getEventDirectoryForCollection: (NSString *) collection {
    return [[self getKeenDirectory] stringByAppendingPathComponent:collection];
}

- (NSArray *) contentsOfDirectoryForCollection: (NSString *) collection {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [manager contentsOfDirectoryAtPath:[self getEventDirectoryForCollection:collection] error:&error];
    if (error) {
        STFail(@"Error when listing contents of directory for collection %@: %@", collection, [error localizedDescription]);
    }
    return contents;
}

@end
