//
//  KeenClient.m
//  KeenClient
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenClient.h"

static NSDictionary *clients;

@interface KeenClient () {}

// The authorization token for this particular project.
@property (nonatomic, retain) NSString *token;

// The timestamp for the previous event.
@property (nonatomic, retain) NSDate *prevTimestamp;

// How many times the previous timestamp has been used.
@property (nonatomic) NSInteger numTimesTimestampUsed;

/**
 Initializes a KeenClient with the given authToken.
 @param authToken The auth token corresponding to the keen.io project.
 @returns an instance of KeenClient, or nil if authToken is nil or otherwise invalid.
 */
- (id) initWithAuthToken: (NSString *) authToken;

/**
 Returns the app's documents directory.
 @returns An NSString* that is a path to the app's documents directory.
 */
- (NSString *) getDocumentsDirectory;

/**
 Returns the root keen directory where collection sub-directories exist.
 @returns An NSString* that is a path to the keen root directory.
 */
- (NSString *) getKeenDirectory;

/**
 Returns the directory for a particular collection where events exist.
 @param collection The collection.
 @returns An NSString* that is a path to the collection directory.
 */
- (NSString *) getEventDirectoryForCollection: (NSString *) collection;

/**
 Returns the full path to write an event to.
 @param collection The collection name.
 @param timestamp  The timestamp of the event.
 @returns An NSString* that is a path to the event to be written.
 */
- (NSString *) getPathForEventInCollection: (NSString *) collection WithTimestamp: (NSDate *) timestamp;
    
@end

@implementation KeenClient

@synthesize token=_token;
@synthesize prevTimestamp=_prevTimestamp;
@synthesize numTimesTimestampUsed=_numTimesTimestampUsed;

# pragma mark - Class lifecycle

+ (void) initialize {
    // initialize the dictionary used to cache clients exactly once.
    if (!clients) {
        clients = [[NSMutableDictionary dictionary] retain];
    }
}

- (id) initWithAuthToken:(NSString *)authToken {
    self = [super init];
    if (self) {
        NSLog(@"Called init on KeenClient for token: %@", authToken);
        self.token = authToken;
        self.prevTimestamp = nil;
    }
    
    return self;
}

- (void) dealloc {
    self.token = nil;
    self.prevTimestamp = nil;
    [super dealloc];
}

# pragma mark - Get a client

+ (KeenClient *) getClientForAuthToken: (NSString *) authToken {
    // validate that auth token is acceptable
    if (!authToken) {
        return nil;
    }
    
    @synchronized(self) {
        // grab whatever's in the cache.
        KeenClient *client = [clients objectForKey:authToken];
        // if it's null, then create a new instance.
        if (!client) {
            // new instance
            client = [[KeenClient alloc] initWithAuthToken:authToken];
            // cache it
            [clients setValue:client forKey:authToken];
            // release it
            [client release];
        }
        return client;
    }
}

# pragma mark - Add events and upload them

- (Boolean) addEvent: (NSDictionary *) event ToCollection: (NSString *) collection {
    // don't do anything if event or collection are nil.
    if (!event || !collection) {
        return NO;
    }
    
    NSDictionary *eventToWrite = nil;
    // if there's no timestamp in the event, stamp it automatically.
    NSDate *timestamp = [event objectForKey:@"timestamp"];
    if (!timestamp) {
        eventToWrite = [NSMutableDictionary dictionaryWithDictionary:event];
        timestamp = [NSDate date];
        [eventToWrite setValue:timestamp forKey:@"timestamp"];
    } else {
        eventToWrite = event;
    }
    
    // get a file manager so we can interact with the file system.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // make sure the directory we want to write the file to exists
    NSString *dirPath = [self getEventDirectoryForCollection:collection];
    // if the directory doesn't exist, create it.
    if (![fileManager fileExistsAtPath:dirPath]) {
        NSError *error = nil;
        Boolean success = [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"An error occurred when creating directory (%@). Message: %@", dirPath, [error localizedDescription]);
            return NO;
        } else if (!success) {
            NSLog(@"Failed to create directory (%@) but no error was returned.", dirPath);
            return NO;
        }        
    }
    
    // now figure out the correct filename.
    NSString *fileName = [self getPathForEventInCollection:collection WithTimestamp:timestamp];
    
    // write file atomically so we don't ever have a partial event to worry about.
    Boolean success = [eventToWrite writeToFile:fileName atomically:YES];
    if (!success) {
        NSLog(@"Error when writing event to file: %@", fileName);
        return NO;
    } else {
        NSLog(@"Successfully wrote event to file: %@", fileName);
    }
    
    return YES;    
}

- (void) upload {
    // get a file manager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // list all the directories under Keen
    NSString *rootPath = [self getKeenDirectory];
    NSError *error = nil;
    NSArray *directories = [fileManager contentsOfDirectoryAtPath:rootPath error:&error];
    if (error) {
        NSLog(@"An error occurred when listing keen root directory contents: %@", [error localizedDescription]);
        return;
    }
    
    // iterate through each directory
    for (NSString *dirName in directories) {
        // list contents of each directory
        NSString *dirPath = [rootPath stringByAppendingPathComponent:dirName];
        error = nil;
        NSArray *files = [fileManager contentsOfDirectoryAtPath:dirPath error:&error];
        if (error) {
            NSLog(@"An error occurred when listing directory (%@) contents: %@", dirPath, [error localizedDescription]);
            continue;
        }
        
        for (NSString *fileName in files) {
            NSString *filePath = [dirPath stringByAppendingPathComponent:fileName];
            // for each file, deserialize the dictionary into memory.
            NSDictionary *event = [NSDictionary dictionaryWithContentsOfFile:filePath];
            if (!event) {
                NSLog(@"Couldn't deserialize file (%@). Deleting it.", filePath);
                error = nil;
                [fileManager removeItemAtPath:filePath error:&error];
            }
            
            // then serialize the dictionary to json.
            
        }
        
        // and then make an http request to the keen server.
        // if the request succeeded, delete the event from the local file system.
        // if the request failed because the event was malformed, delete the event from the local file system.
        // if the request failed because the server was down, keep the event on the local file system for later upload.
    }    
}

# pragma mark - Directory/path management

- (NSString *) getDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (NSString *) getKeenDirectory {
    return [[self getDocumentsDirectory] stringByAppendingPathComponent:@"keen"];
}

- (NSString *) getEventDirectoryForCollection: (NSString *) collection {
    return [[self getKeenDirectory] stringByAppendingPathComponent:collection];
}

- (NSString *) getPathForEventInCollection: (NSString *) collection WithTimestamp: (NSDate *) timestamp {
    // get a file manager.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // determine the root of the filename.
    NSString *name = [NSString stringWithFormat:@"%d", (long) [timestamp timeIntervalSince1970]];
    // get the path to the directory where the file will be written
    NSString *directory = [self getEventDirectoryForCollection:collection];
    // start a counter that we'll use to make sure that even if multiple events are written with the same timestamp,
    // we'll be able to handle it.
    uint count = 0;
    
    // declare a tiny helper block to get the next path based on the counter.
    NSString * (^getNextPath)(uint count) = ^(uint count) {
        return [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%i", name, count]];
    };
    
    // starting with our root filename.0, see if a file exists.  if it doesn't, great.  but if it does, then go
    // on to filename.1, filename.2, etc.
    NSString *path = getNextPath(count);
    while ([fileManager fileExistsAtPath:path]) {
        count++;
        path = getNextPath(count);
    }    
    
    return path;
}

@end
