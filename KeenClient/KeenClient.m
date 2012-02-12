//
//  KeenClient.m
//  KeenClient
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenClient.h"
#import "CJSONSerializer.h"
#import "CJSONDeserializer.h"


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
 Returns the path to the app's library/cache directory.
 @returns An NSString* that is a path to the app's documents directory.
 */
- (NSString *) getCacheDirectory;

/**
 Returns the root keen directory where collection sub-directories exist.
 @returns An NSString* that is a path to the keen root directory.
 */
- (NSString *) getKeenDirectory;

// TODO comment
- (NSArray *) getKeenSubDirectories;
- (NSArray *) getContentsAtPath: (NSString *) path;

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

// TODO comment
- (Boolean) createDirectoryIfItDoesNotExist: (NSString *) dirPath;
- (Boolean) writeNSData: (NSData *) data toFile: (NSString *) file;
    
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
    
    // serialize event to JSON
    NSError *error = nil;
    NSData *jsonData = [[CJSONSerializer serializer] serializeDictionary:eventToWrite error:&error];
    if (error) {
        NSLog(@"An error occurred when serializing event to JSON: %@", [error localizedDescription]);
        return NO;
    }
    
    // make sure the directory we want to write the file to exists
    NSString *dirPath = [self getEventDirectoryForCollection:collection];
    // if the directory doesn't exist, create it.
    Boolean success = [self createDirectoryIfItDoesNotExist:dirPath];
    if (!success) {
        return NO;
    }
    
    // now figure out the correct filename.
    NSString *fileName = [self getPathForEventInCollection:collection WithTimestamp:timestamp];
    
    // write JSON to file system
    return [self writeNSData:jsonData toFile:fileName];
}

- (void) upload {
    // get a file manager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // list all the directories under Keen
    NSArray *directories = [self getKeenSubDirectories];
    NSString *rootPath = [self getKeenDirectory];
    
    // iterate through each directory
    for (NSString *dirName in directories) {
        // list contents of each directory
        NSString *dirPath = [rootPath stringByAppendingPathComponent:dirName];
        NSError *error = nil;
        NSArray *files = [self getContentsAtPath:dirPath];
        
        for (NSString *fileName in files) {
            NSString *filePath = [dirPath stringByAppendingPathComponent:fileName];
            // for each file, deserialize the dictionary into memory.
            NSDictionary *event = [NSDictionary dictionaryWithContentsOfFile:filePath];
            if (!event) {
                NSLog(@"Couldn't deserialize file (%@). Deleting it.", filePath);
                [fileManager removeItemAtPath:filePath error:&error];
            }
            
            // then serialize the dictionary to json.
            error = nil;
            NSData *data = [[CJSONSerializer serializer] serializeDictionary:event error:&error];
            if (error) {
                NSLog(@"Couldn't serialize %@ to JSON.", event);
                [fileManager removeItemAtPath:filePath error:&error];
            }
            
            // and then make an http request to the keen server.
            // TODO get project ID in there
            NSString *urlString = [NSString stringWithFormat:@"http://api.keen.io/v1.0/projects/%@/%@", nil, dirName];
            NSURL *url = [NSURL URLWithString:urlString];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:self.token forHTTPHeaderField:@"Authorization"];
            // TODO check if setHTTPBody also sets content-length
            [request setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
            [request setHTTPBody:data];
            NSURLResponse *response = nil;
            error = nil;
            NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
            if (error) {
                // if the request failed because the server was down, keep the event on the local file system for later upload.
                NSLog(@"An error occurred when sending HTTP request: %@", [error localizedDescription]);
                continue;
            }
            
            if (!responseData) {
                NSLog(@"responseData was nil for some reason.  That's not great.");
                continue;
            }
            
            // if the request failed because the event was malformed, delete the event from the local file system.
            error = nil;
            NSDictionary *responseDict = [[CJSONDeserializer deserializer] deserializeAsDictionary:responseData error:&error];
            if (error) {
                NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                NSLog(@"An error occurred when deserializing HTTP response JSON into dictionary.\nError: %@\nResponse: %@", [error localizedDescription], responseString);
                [responseString release];
                continue;
            }
            NSString *errorCode = [responseDict objectForKey:@"error_code"];
            if ([errorCode isEqualToString:@"InvalidCollectionNameError"] ||
                [errorCode isEqualToString:@"InvalidPropertyNameError"] ||
                [errorCode isEqualToString:@"InvalidPropertyValueError"]) {
                error = nil;
                [fileManager removeItemAtPath:filePath error:&error];
                if (error) {
                    NSLog(@"CRITICAL ERROR: Could not remove event at %@ because: %@", filePath, [error localizedDescription]);
                    continue;
                }
            }
                        
            // if the request succeeded, delete the event from the local file system.
            if ([((NSHTTPURLResponse *)response) statusCode] == 201) {
                error = nil;
                [fileManager removeItemAtPath:filePath error:&error];
                if (error) {
                    NSLog(@"CRITICAL ERROR: Could not remove event at %@ because: %@", filePath, [error localizedDescription]);
                    continue;
                }
            }
        }
    }    
}

# pragma mark - Directory/path management

- (NSString *) getCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (NSString *) getKeenDirectory {
    return [[self getCacheDirectory] stringByAppendingPathComponent:@"keen"];
}

- (NSArray *) getKeenSubDirectories {
    return [self getContentsAtPath:[self getKeenDirectory]];
}

- (NSArray *) getContentsAtPath: (NSString *) path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        NSLog(@"An error occurred when listing directory (%@) contents: %@", path, [error localizedDescription]);
        return nil;
    }
    return files;
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

- (Boolean) createDirectoryIfItDoesNotExist: (NSString *) dirPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
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
    return YES;
}

- (Boolean) writeNSData: (NSData *) data toFile: (NSString *) file {
    // write file atomically so we don't ever have a partial event to worry about.    
    Boolean success = [data writeToFile:file atomically:YES];
    if (!success) {
        NSLog(@"Error when writing event to file: %@", file);
        return NO;
    } else {
        NSLog(@"Successfully wrote event to file: %@", file);
    }
    return YES;
}

@end
