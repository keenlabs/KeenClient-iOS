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
#import "KeenClientConfig.h"
#import "KIOReachability.h"
#import "KIODBStore.h"
#import "KIONetwork.h"
#import "KIOFileStore.h"
#import "KIOUploader.h"
#import "KIOUtil.h"

@interface KIOUploader ()

- (BOOL)isNetworkConnected;

- (void)runUploadFinishedBlock:(UploadCompletionBlock)completionBlock error:(NSError *)error;

/**
 Handles the HTTP response from the Keen Event API.  This involves deserializing the JSON response
 and then removing any events from the local filesystem that have been handled by the keen API.
 @param response The response from the server.
 @param responseData The data returned from the server.
 @param eventIds A dictionary that maps events to their ID's in the local store.
 */
- (void)handleEventAPIResponse:(NSURLResponse *)response
                       andData:(NSData *)responseData
                     forEvents:(NSDictionary *)eventIds
                 responseError:(NSError *)responseError
                         error:(NSError **)error;

// A dispatch queue used for uploads.
@property (nonatomic) dispatch_queue_t uploadQueue;

@property (nonatomic) KIODBStore *store;

@property (nonatomic) KIONetwork *network;

@property BOOL isUploading;

@property NSCondition *isUploadingCondition;

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
        s_sharedInstance =
            [[KIOUploader alloc] initWithNetwork:KIONetwork.sharedInstance andStore:KIODBStore.sharedInstance];
    });

    return s_sharedInstance;
}

- (instancetype)initWithNetwork:(KIONetwork *)network andStore:(KIODBStore *)store {
    self = [super init];
    if (self) {
        // Create a serialized queue to handle all upload operations
        self.uploadQueue = dispatch_queue_create("io.keen.uploader", DISPATCH_QUEUE_SERIAL);

        self.maxEventUploadAttempts = 3;

        self.isUploadingCondition = [NSCondition new];
        self.isUploading = NO;

        self.network = network;

        self.store = store;
    }
    return self;
}

- (void)prepareJSONData:(NSData **)jsonData
            andEventIDs:(NSMutableDictionary **)eventIDs
           forProjectID:(NSString *)projectID
                  error:(NSError **)ppError {
    NSError *error;

    // set up the request dictionary we'll send out.
    NSMutableDictionary *requestDict = [NSMutableDictionary dictionary];

    // create a structure that will hold corresponding ids of all the events
    NSMutableDictionary *eventIDDict = [NSMutableDictionary dictionary];

    // get data for the API request we'll make
    NSMutableDictionary *events =
        [self.store getEventsWithMaxAttempts:self.maxEventUploadAttempts andProjectID:projectID];

    for (NSString *collection in events) {
        NSDictionary *collectionEvents = events[collection];

        // create a separate array for event data so our dictionary serializes properly
        NSMutableArray *eventsArray = [NSMutableArray array];

        for (NSNumber *eventId in collectionEvents) {
            NSDictionary *eventDictionary = collectionEvents[eventId];
            NSData *eventData = eventDictionary[@"data"];
            NSNumber *eventAttempts = eventDictionary[kKeenEventKeenDataAttemptsKey];

            NSMutableDictionary *eventDict =
                [[NSJSONSerialization JSONObjectWithData:eventData options:0 error:&error] mutableCopy];
            if (error) {
                KCLogError(@"An error occurred when deserializing a saved event: %@", [error localizedDescription]);
                *ppError = [NSError errorWithDomain:kKeenErrorDomain
                                               code:KeenErrorCodeSerialization
                                           userInfo:@{kKeenErrorInnerErrorKey: error}];
                return;
            }

            // Add information about the attempt count
            [eventDict addEntriesFromDictionary:@{kKeenEventKeenDataAttemptsKey: eventAttempts}];

            // add it to the array of events
            [eventsArray addObject:eventDict];
            if (eventIDDict[collection] == nil) {
                eventIDDict[collection] = [NSMutableArray array];
            }
            [eventIDDict[collection] addObject:eventId];
        }

        // add the array of events to the request
        requestDict[collection] = eventsArray;
    }

    if ([requestDict count] == 0) {
        KCLogError(@"Request data is empty");
        return;
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&error];
    if (error) {
        KCLogError(@"An error occurred when serializing the final request data back to JSON: %@",
                   [error localizedDescription]);
        *ppError = [NSError errorWithDomain:kKeenErrorDomain
                                       code:KeenErrorCodeSerialization
                                   userInfo:@{kKeenErrorInnerErrorKey: error}];
        return;
    }

    *jsonData = data;
    *eventIDs = eventIDDict;

    KCLogVerbose(@"Uploading following events to Keen API: %@", requestDict);
}

#pragma mark - Uploading

- (BOOL)isNetworkConnected {
    KIOReachability *hostReachability = [KIOReachability KIOreachabilityForInternetConnection];
    return [hostReachability KIOcurrentReachabilityStatus] != NotReachable;
}

- (void)uploadEventsForConfig:(KeenClientConfig *)config completionHandler:(UploadCompletionBlock)completionHandler {
    dispatch_async(self.uploadQueue, ^{
        NSError *error;

        if (![self isNetworkConnected]) {
            error = [NSError errorWithDomain:kKeenErrorDomain
                                        code:KeenErrorCodeNetworkDisconnected
                                    userInfo:@{
                                        kKeenErrorDescriptionKey: @"Network is disconnected"
                                    }];
            [self runUploadFinishedBlock:completionHandler error:error];
            return;
        }

        // Migrate data from old format if anything exists
        // for this project id.
        [KIOFileStore maybeMigrateDataFromFileStore:config.projectID];

        // get data for the API request we'll make
        NSData *data;
        NSMutableDictionary *eventIDs;
        [self prepareJSONData:&data andEventIDs:&eventIDs forProjectID:config.projectID error:&error];
        if (error != nil) {
            KCLogInfo(@"Error preparing JSON data for upload: %@", error);
            [self runUploadFinishedBlock:completionHandler error:error];
        } else if ([data length] == 0) {
            KCLogInfo(@"No data available for upload.");
            [self runUploadFinishedBlock:completionHandler error:nil];
        } else {
            KCLogInfo(@"Uploading %@ events...", @([eventIDs count]));
            // loop through events and increment their attempt count
            for (NSString *collectionName in eventIDs) {
                for (NSNumber *eid in eventIDs[collectionName]) {
                    [self.store incrementEventUploadAttempts:eid];
                }
            }

            [self.isUploadingCondition lock];
            self.isUploading = YES;
            [self.isUploadingCondition unlock];

            // then make an http request to the keen server.
            [self.network sendEvents:data
                              config:config
                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
                       NSError *localError;
                       // then parse the http response and deal with it appropriately
                       [self handleEventAPIResponse:response
                                            andData:data
                                          forEvents:eventIDs
                                      responseError:responseError
                                              error:&localError];

                       [self runUploadFinishedBlock:completionHandler error:localError];

                       [self.isUploadingCondition lock];
                       self.isUploading = NO;
                       [self.isUploadingCondition signal];
                       [self.isUploadingCondition unlock];
                   }];

            // Block the queue until uploading has finished.
            // Otherwise we'll pick up events that are in flight and try to upload them again
            [self.isUploadingCondition lock];
            while (self.isUploading) {
                [self.isUploadingCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:60]];
            }
            [self.isUploadingCondition unlock];
        }
    });
}

- (void)runUploadFinishedBlock:(UploadCompletionBlock)completionBlock error:(NSError *)error {
    if (completionBlock) {
        KCLogVerbose(@"Running user-specified block.");
        if (nil != error) {
            KCLogError(@"Error uploading events: %@", error);
        }
        completionBlock(error);
    }
}

#pragma mark - HTTP request/response management

- (void)handleEventAPIResponse:(NSURLResponse *)response
                       andData:(NSData *)responseData
                     forEvents:(NSDictionary *)eventIds
                 responseError:(NSError *)responseError
                         error:(NSError **)ppError {
    NSError *error;

    // If there was a response error, return it
    if (nil != responseError) {
        *ppError = [NSError errorWithDomain:kKeenErrorDomain
                                       code:KeenErrorCodeResponseError
                                   userInfo:@{kKeenErrorInnerErrorKey: responseError}];
        return;
    }

    NSInteger responseCode = [((NSHTTPURLResponse *)response)statusCode];
    if ([HTTPCodes httpCodeType:(responseCode)] != HTTPCode2XXSuccess) {
        // response code was NOT 2xx, which means something else happened. log this.
        NSString *responseString =
            responseData ? [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] : @"";
        NSString *errorDescription =
            [NSString stringWithFormat:@"Response returned non-success code: %@\nResponse body was: %@",
                                       @(responseCode),
                                       responseString];
        KCLogError(@"%@", errorDescription);
        *ppError = [NSError errorWithDomain:kKeenErrorDomain
                                       code:KeenErrorCodeResponseError
                                   userInfo:@{
                                       kKeenErrorDescriptionKey: errorDescription,
                                       kKeenErrorHttpStatus: @(responseCode)
                                   }];
        return;
    }

    // If for some reason there was no response body and no error, generate an error and return it
    if (!responseData) {
        KCLogError(@"responseData was nil for some reason.  That's not great.");
        KCLogError(@"response status code: %ld", (long)[((NSHTTPURLResponse *)response)statusCode]);
        *ppError = [NSError errorWithDomain:kKeenErrorDomain
                                       code:KeenErrorCodeResponseError
                                   userInfo:@{
                                       kKeenErrorDescriptionKey: @"Response body was empty"
                                   }];
        return;
    }

    // if the request succeeded, dig into the response to figure out which events succeeded and which failed
    // deserialize the response
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
    if (error) {
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSString *errorDescription = [NSString
            stringWithFormat:
                @"An error occurred when deserializing HTTP response JSON into dictionary.\nError: %@\nResponse: %@",
                [error localizedDescription],
                responseString];
        KCLogError(@"%@", errorDescription);
        *ppError = [NSError errorWithDomain:kKeenErrorDomain
                                       code:KeenErrorCodeSerialization
                                   userInfo:@{kKeenErrorDescriptionKey: errorDescription}];

        return;
    }

    // now iterate through the keys of the response, which represent collection names
    NSMutableArray *errors = [NSMutableArray array];
    NSArray *collectionNames = [responseDict allKeys];
    for (NSString *collectionName in collectionNames) {
        // grab the results for this collection
        NSArray *results = [responseDict objectForKey:collectionName];
        // go through and delete any successes and failures because of user error
        // (making sure to keep any failures due to server error)
        NSUInteger count = 0;
        for (NSDictionary *result in results) {
            BOOL deleteEvent = YES;
            BOOL success = [[result objectForKey:kKeenSuccessParam] boolValue];
            if (!success) {
                // grab error code and description
                NSString *errorDescription;
                NSDictionary *errorDict = result[kKeenResponseErrorDictionaryKey];
                NSString *errorName = errorDict[kKeenResponseErrorNameKey];

                if ([errorName isEqualToString:kKeenInvalidCollectionNameError] ||
                    [errorName isEqualToString:kKeenInvalidPropertyNameError] ||
                    [errorName isEqualToString:kKeenInvalidPropertyValueError]) {
                    errorDescription = [NSString
                        stringWithFormat:@"An invalid event was found. Deleting it. Error name and description: %@, %@",
                                         errorName,
                                         errorDict[kKeenResponseErrorDescriptionKey]];
                    deleteEvent = YES;
                } else {
                    errorDescription =
                        [NSString stringWithFormat:@"The event could not be inserted for some reason. Will retry "
                                                   @"during next upload if max attempts haven't been reached. Error "
                                                   @"name and description: %@, %@",
                                                   errorName,
                                                   errorDict[kKeenResponseErrorDescriptionKey]];
                    deleteEvent = NO;
                }

                KCLogError(@"%@", errorDescription);
                [errors addObject:[NSError errorWithDomain:kKeenErrorDomain
                                                      code:KeenErrorCodeEventUploadError
                                                  userInfo:@{
                                                      kKeenErrorDescriptionKey: errorDescription,
                                                      kKeenResponseErrorNameKey: errorName,
                                                      kKeenResponseErrorDictionaryKey: errorDict
                                                  }]];
            }

            NSNumber *eid = [[eventIds objectForKey:collectionName] objectAtIndex:count];

            // delete the file if we need to
            if (deleteEvent) {
                [self.store deleteEvent:eid];
                KCLogVerbose(@"Successfully deleted event: %@", eid);
            }
            count++;
        }
    }

    // Report any errors that occured
    if (errors.count > 0) {
        KCLogError(@"%@ errors while trying to upload events", @(errors.count));
        *ppError = [NSError errorWithDomain:kKeenErrorDomain
                                       code:KeenErrorCodeEventUploadError
                                   userInfo:@{kKeenErrorInnerErrorArrayKey: errors}];
    }
}

@end
