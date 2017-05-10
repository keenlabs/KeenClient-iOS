//
//  KIOFileStore.h
//  KeenClient
//
//  Created by Brian Baumhover on 3/22/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenConstants.h"
#import "KeenClient.h"
#import "KIOFileStore.h"

// Utilities for dealing with deprecated
// filesystem based event store
@interface KIOFileStore ()

// Get the cache directory
+ (NSString *)cacheDirectory;

// Get the directory for storage of events for a given project
+ (NSString *)keenDirectoryForProjectID:(NSString *)projectID;

// Get subdirectories under path for a given project
+ (NSArray *)keenSubDirectoriesForProjectID:(NSString *)projectID;

// Get the file contents at a given path
+ (NSArray *)contentsAtPath:(NSString *)path;

// Get the event directory for a collection and project
+ (NSString *)eventDirectoryForProjectID:(NSString *)projectID andCollection:(NSString *)collection;

@end

@implementation KIOFileStore

+ (NSString *)cacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

+ (NSString *)keenDirectoryForProjectID:(NSString *)projectID {
    NSString *keenDirPath = [[self cacheDirectory] stringByAppendingPathComponent:@"keen"];
    return [keenDirPath stringByAppendingPathComponent:projectID];
}

+ (NSArray *)keenSubDirectoriesForProjectID:(NSString *)projectID {
    return [self contentsAtPath:[self keenDirectoryForProjectID:projectID]];
}

+ (NSArray *)contentsAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        KCLogError(@"An error occurred when listing directory (%@) contents: %@", path, [error localizedDescription]);
        return nil;
    }
    return files;
}

+ (NSString *)eventDirectoryForProjectID:(NSString *)projectID andCollection:(NSString *)collection {
    return [[self keenDirectoryForProjectID:projectID] stringByAppendingPathComponent:collection];
}

+ (NSString *)pathForEventForProjectID:(NSString *)projectID
                          inCollection:(NSString *)collection
                         withTimestamp:(NSDate *)timestamp {
    // get a file manager.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // determine the root of the filename.
    NSString *name = [NSString stringWithFormat:@"%f", [timestamp timeIntervalSince1970]];
    // get the path to the directory where the file will be written
    NSString *directory = [self eventDirectoryForProjectID:projectID andCollection:collection];
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

+ (void)importFileDataWithProjectID:(NSString *)projectID {
    // Save a flag that we've done the FS import so we don't waste
    // time on it in the future.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:true forKey:kKeenFileStoreImportedKey];
    [defaults synchronize];

    @try {
        // list all the directories under Keen
        NSString *rootPath = [self keenDirectoryForProjectID:projectID];

        // Get a file manager so we can use it later
        NSFileManager *fileManager = [NSFileManager defaultManager];

        // We only need to do this import if the directory exists so check
        // that out first.
        if ([fileManager fileExistsAtPath:rootPath]) {
            // declare an error object
            NSError *error = nil;

            // iterate through each directory
            NSArray *directories = [self keenSubDirectoriesForProjectID:projectID];
            for (NSString *dirName in directories) {
                KCLogVerbose(@"Found directory: %@", dirName);
                // list contents of each directory
                NSString *dirPath = [rootPath stringByAppendingPathComponent:dirName];
                NSArray *files = [self contentsAtPath:dirPath];

                for (NSString *fileName in files) {
                    KCLogVerbose(@"Found file: %@/%@", dirName, fileName);
                    NSString *filePath = [dirPath stringByAppendingPathComponent:fileName];
                    // for each file, grab the JSON blob
                    NSData *data = [NSData dataWithContentsOfFile:filePath];
                    // deserialize it
                    error = nil;
                    if ([data length] > 0) {
                        // Attempt to deserialize this just to determine if it's valid
                        // or not. We don't actually care about the results.
                        [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                        if (error) {
                            // If we got an error we're not gonna add it
                            KCLogError(@"An error occurred when deserializing a saved event: %@",
                                       [error localizedDescription]);
                        } else {
                            // All's well: Add it!
                            [KIODBStore.sharedInstance addEvent:data collection:dirName projectID:projectID];
                        }
                    }
                    // Regardless, delete it when we're done.
                    [fileManager removeItemAtPath:filePath error:nil];
                }
            }
            // Remove the keen directory at the end so we know not to do this again!
            [fileManager removeItemAtPath:rootPath error:nil];
        }
    } @catch (NSException *e) {
        KCLogError(@"An error occurred when attempting to import events from the filesystem, will not run again: %@",
                   e);
    }
}

+ (void)maybeMigrateDataFromFileStore:(NSString *)projectID {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Check if we've done an import before. (A missing value returns NO)
    if (![defaults boolForKey:kKeenFileStoreImportedKey]) {
        // Slurp in any filesystem based events. This converts older fs-based
        // event storage into newer SQL-lite based storage.
        [self importFileDataWithProjectID:projectID];
    }
}

@end
