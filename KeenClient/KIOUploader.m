//
//  KIOUploader.m
//  KeenClient
//
//  Created by Brian Baumhover on 3/22/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "HTTPCodes.h"
#import "KeenConstants.h"
#import "KeenClient.h"
#import "KIOReachability.h"
#import "KIODBStore.h"
#import "KIONetwork.h"
#import "KIOFileStore.h"
#import "KIOUploader.h"

@interface KIOUploader ()

- (BOOL)isNetworkConnected;

- (void)runUploadFinishedBlock:(void (^)())block;

/**
 Handles the HTTP response from the Keen Event API.  This involves deserializing the JSON response
 and then removing any events from the local filesystem that have been handled by the keen API.
 @param response The response from the server.
 @param responseData The data returned from the server.
 @param eventIds A dictionary that maps events to their ID's in the local store.
 */
- (void)handleEventAPIResponse:(NSURLResponse *)response
                       andData:(NSData *)responseData
                     forEvents:(NSDictionary *)eventIds;


// A dispatch queue used for uploads.
@property (nonatomic) dispatch_queue_t uploadQueue;

@property (nonatomic) KIODBStore *store;

@property (nonatomic) KIONetwork *network;

@end


@implementation KIOUploader


+ (instancetype)sharedInstance {
    static KIOUploader *s_sharedInstance;

    // This black magic ensures this block
    // is dispatched only once over the lifetime
    // of the program. It's nice because
    // this works even when there's a race
    // between threads to create the object,
    // as both threads will wait synchronously
    // for the block to complete.
    static dispatch_once_t predicate = {0};
    dispatch_once(&predicate, ^{
        s_sharedInstance = [[KIOUploader alloc] initWithNetwork:KIONetwork.sharedInstance
                                                       andStore:KIODBStore.sharedInstance];
    });

    return s_sharedInstance;
}

- (instancetype)initWithNetwork:(KIONetwork *)network
                       andStore:(KIODBStore *)store {
    self = [super init];
    if (self) {
        // Create a serialized queue to handle all upload operations
        self.uploadQueue = dispatch_queue_create("io.keen.uploader", DISPATCH_QUEUE_SERIAL);

        self.maxEventUploadAttempts = 3;

        self.network = network;

        self.store = store;
    }
    return self;
}


- (void)prepareJSONData:(NSData **)jsonData
            andEventIDs:(NSMutableDictionary **)eventIDs
           forProjectID:(NSString *)projectID {
    // set up the request dictionary we'll send out.
    NSMutableDictionary *requestDict = [NSMutableDictionary dictionary];

    // create a structure that will hold corresponding ids of all the events
    NSMutableDictionary *eventIDDict = [NSMutableDictionary dictionary];

    // get data for the API request we'll make
    NSMutableDictionary *events = [self.store getEventsWithMaxAttempts:self.maxEventUploadAttempts
                                                          andProjectID:projectID];

    NSError *error;
    for (NSString *coll in events) {
        NSDictionary *collEvents = [events objectForKey:coll];

        // create a separate array for event data so our dictionary serializes properly
        NSMutableArray *eventsArray = [NSMutableArray array];

        for (NSNumber *eid in collEvents) {
            NSData *ev = [collEvents objectForKey:eid];
            NSDictionary *eventDict = [NSJSONSerialization JSONObjectWithData:ev
                                                                      options:0
                                                                        error:&error];
            if (error) {
                KCLogError(@"An error occurred when deserializing a saved event: %@", [error localizedDescription]);
                continue;
            }

            // add it to the array of events
            [eventsArray addObject:eventDict];
            if ([eventIDDict objectForKey:coll] == nil) {
                [eventIDDict setObject: [NSMutableArray array] forKey:coll];
            }
            [[eventIDDict objectForKey:coll] addObject:eid];
        }

        // add the array of events to the request
        [requestDict setObject:eventsArray forKey:coll];
    }

    if ([requestDict count] == 0) {
        KCLogError(@"Request data is empty");
        return;
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&error];
    if (error) {
        KCLogError(@"An error occurred when serializing the final request data back to JSON: %@",
              [error localizedDescription]);
        // can't do much here.
        return;
    }

    *jsonData = data;
    *eventIDs = eventIDDict;

    KCLogVerbose(@"Uploading following events to Keen API: %@", requestDict);
}


# pragma mark - Uploading

- (BOOL)isNetworkConnected {
    KIOReachability *hostReachability = [KIOReachability KIOreachabilityForInternetConnection];
    return [hostReachability KIOcurrentReachabilityStatus] != NotReachable;
}

- (void)uploadEventsForProjectID:(NSString *)projectID
                    withWriteKey:(NSString *)writeKey
               withFinishedBlock:(void (^)())block {
    dispatch_async(self.uploadQueue, ^{
        if (![self isNetworkConnected]) {
            [self runUploadFinishedBlock:block];
            return;
        }

        // Migrate data from old format if anything exists
        // for this project id.
        [KIOFileStore maybeMigrateDataFromFileStore:projectID];

        // get data for the API request we'll make
        NSData *data;
        NSMutableDictionary *eventIDs;
        [self prepareJSONData:&data andEventIDs:&eventIDs forProjectID:projectID];

        if ([data length] == 0) {
            [self runUploadFinishedBlock:block];
        } else {
            // loop through events and increment their attempt count
            for (NSString *collectionName in eventIDs) {
                for (NSNumber *eid in eventIDs[collectionName]) {
                    [self.store incrementEventUploadAttempts:eid];
                }
            }

            // then make an http request to the keen server.
            [self.network sendEvents:data
                       withProjectID:projectID
                        withWriteKey:writeKey
                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                // then parse the http response and deal with it appropriately
                [self handleEventAPIResponse:response andData:data forEvents:eventIDs];

                [self runUploadFinishedBlock:block];
            }];
        }
    });
}

- (void)runUploadFinishedBlock:(void (^)())block {
    if (block) {
        KCLogVerbose(@"Running user-specified block.");
        @try {
            block();
        } @catch(NSException *exception) {
            KCLogError(@"Error executing user-specified block. \nName: %@\nReason: %@", exception.name, exception.reason);
        }
    }
}


# pragma mark - HTTP request/response management

- (void)handleEventAPIResponse:(NSURLResponse *)response
                       andData:(NSData *)responseData
                     forEvents:(NSDictionary *)eventIds {
    if (!responseData) {
        KCLogError(@"responseData was nil for some reason.  That's not great.");
        KCLogError(@"response status code: %ld", (long)[((NSHTTPURLResponse *) response) statusCode]);
        return;
    }
    NSInteger responseCode = [((NSHTTPURLResponse *)response) statusCode];
    if ([HTTPCodes httpCodeType:(responseCode)] != HTTPCode2XXSuccess) {
        // response code was NOT 2xx, which means something else happened. log this.
        KCLogError(@"Response code was NOT 2xx. It was: %ld", (long)responseCode);
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        KCLogError(@"Response body was: %@", responseString);
        return;
    }

    // if the request succeeded, dig into the response to figure out which events succeeded and which failed
    // deserialize the response
    NSError *error;
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData
                                                                 options:0
                                                                   error:&error];
    if (error) {
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        KCLogError(@"An error occurred when deserializing HTTP response JSON into dictionary.\nError: %@\nResponse: %@",
                   [error localizedDescription],
                   responseString);
        return;
    }
    // now iterate through the keys of the response, which represent collection names
    NSArray *collectionNames = [responseDict allKeys];
    for (NSString *collectionName in collectionNames) {
        // grab the results for this collection
        NSArray *results = [responseDict objectForKey:collectionName];
        // go through and delete any successes and failures because of user error
        // (making sure to keep any failures due to server error)
        NSUInteger count = 0;
        for (NSDictionary *result in results) {
            BOOL deleteFile = YES;
            BOOL success = [[result objectForKey:kKeenSuccessParam] boolValue];
            if (!success) {
                // grab error code and description
                NSDictionary *errorDict = [result objectForKey:kKeenErrorParam];
                NSString *errorCode = [errorDict objectForKey:kKeenNameParam];
                if ([errorCode isEqualToString:kKeenInvalidCollectionNameError] ||
                    [errorCode isEqualToString:kKeenInvalidPropertyNameError] ||
                    [errorCode isEqualToString:kKeenInvalidPropertyValueError]) {
                    KCLogError(@"An invalid event was found.  Deleting it.  Error: %@",
                               [errorDict objectForKey:kKeenDescriptionParam]);
                    deleteFile = YES;
                } else {
                    KCLogError(@"The event could not be inserted for some reason.  Error name and description: %@, %@",
                               errorCode, [errorDict objectForKey:kKeenDescriptionParam]);
                    deleteFile = NO;
                }
            }

            NSNumber *eid = [[eventIds objectForKey:collectionName] objectAtIndex:count];

            // delete the file if we need to
            if (deleteFile) {
                [self.store deleteEvent:eid];
                KCLogVerbose(@"Successfully deleted event: %@", eid);
            }
            count++;
        }
    }
}


@end
