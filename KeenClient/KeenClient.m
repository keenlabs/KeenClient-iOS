//
//  KeenClient.m
//  KeenClient
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CFNetwork/CFNetwork.h>

#import "KeenClient.h"
#import "KeenConstants.h"
#import "KeenClientConfig.h"
#import "KIOUtil.h"
#import "KIODBStore.h"
#import "KIOReachability.h"
#import "HTTPCodes.h"
#import "KIOQuery.h"
#import "KIOFileStore.h"
#import "KIONetwork.h"
#import "KIOUploader.h"
#import "KeenLogger.h"
#import "KeenLogSinkNSLog.h"

static BOOL authorizedGeoLocationAlways = NO;
static BOOL authorizedGeoLocationWhenInUse = NO;
static BOOL geoLocationEnabled = NO;
static BOOL geoLocationRequestEnabled = YES;

@interface KeenClient ()

// Configuration for the client, including project id and authorization
@property KeenClientConfig *config;

// NSLocationManager
@property (nonatomic) CLLocationManager *locationManager;

// How many times the previous timestamp has been used.
@property (nonatomic) NSInteger numTimesTimestampUsed;

// The max number of events per collection.
@property (nonatomic, readonly) NSUInteger maxEventsPerCollection;

// The number of events to drop when aging out a collection.
@property (nonatomic, readonly) NSUInteger numberEventsToForget;

// A dispatch queue used for querying.
@property (nonatomic) dispatch_queue_t queryQueue;

// If we're running tests.
@property (nonatomic) BOOL isRunningTests;

// Component for doing network operations
@property (nonatomic) KIONetwork *network;

// Component for event durability
@property (nonatomic) KIODBStore *store;

// Component for handling event uploads
@property (nonatomic) KIOUploader *uploader;

/**
 Initializes KeenClient without setting its project ID or API key.
 @returns An instance of KeenClient.
 */
- (id)init;

@end

@implementation KeenClient

/**
 The maximum number of times to try POSTing an event before purging it from the DB.
 */
- (int)maxEventUploadAttempts {
    return self.uploader.maxEventUploadAttempts;
}

- (void)setMaxEventUploadAttempts:(int)maxEventUploadAttempts {
    self.uploader.maxEventUploadAttempts = maxEventUploadAttempts;
}

/**
 The maximum number of times to try a query before stop attempting it.
 */
- (int)maxQueryAttempts {
    return self.network.maxQueryAttempts;
}

- (void)setMaxQueryAttempts:(int)attempts {
    self.network.maxQueryAttempts = attempts;
}

/**
 The number of seconds before deleting a failed query from the database.
 */
- (int)queryTTL {
    return self.network.queryTTL;
}

- (void)setQueryTTL:(int)queryTTL {
    self.network.queryTTL = queryTTL;
}

#pragma mark - Class lifecycle

+ (void)initialize {
    // initialize the cached client exactly once.

    if (self != [KeenClient class]) {
        /*
         Without this extra check, your initializations could run twice if you ever have a subclass that
         doesn't implement its own +initialize method. This is not just a theoretical concern, even if
         you don't write any subclasses. Apple's Key-Value Observing creates dynamic subclasses which
         don't override +initialize.
         */
        return;
    }

    [KeenClient disableLogging];
    [KeenClient enableGeoLocation];
}

+ (void)disableLogging {
    [[KeenLogger sharedLogger] disableLogging];
}

+ (void)enableLogging {
    [[KeenLogger sharedLogger] enableLogging];
}

+ (BOOL)isLoggingEnabled {
    return [[KeenLogger sharedLogger] isLoggingEnabled];
}

+ (void)setIsNSLogEnabled:(BOOL)isNSLogEnabled {
    [[KeenLogger sharedLogger] setIsNSLogEnabled:isNSLogEnabled];
}

+ (BOOL)isNSLogEnabled {
    return [[KeenLogger sharedLogger] isNSLogEnabled];
}

+ (void)addLogSink:(id<KeenLogSink>)sink {
    [[KeenLogger sharedLogger] addLogSink:sink];
}

+ (void)removeLogSink:(id<KeenLogSink>)sink {
    [[KeenLogger sharedLogger] removeLogSink:sink];
}

+ (void)setLogLevel:(KeenLogLevel)level {
    [[KeenLogger sharedLogger] setLogLevel:level];
}

+ (void)logMessageWithLevel:(KeenLogLevel)level andMessage:(NSString *)message {
    [[KeenLogger sharedLogger] logMessageWithLevel:level andMessage:message];
}

+ (void)authorizeGeoLocationAlways {
    KCLogInfo(@"Authorizing Geo Location Always");
    authorizedGeoLocationAlways = YES;
}

+ (void)authorizeGeoLocationWhenInUse {
    KCLogInfo(@"Authorizing Geo Location When In Use");
    authorizedGeoLocationWhenInUse = YES;
}

+ (void)enableGeoLocation {
    KCLogInfo(@"Enabling Geo Location");
    geoLocationEnabled = YES;
}

+ (void)disableGeoLocation {
    KCLogInfo(@"Disabling Geo Location");
    geoLocationEnabled = NO;
}
+ (void)enableGeoLocationDefaultRequest {
    KCLogInfo(@"Enabling Geo Location Request");
    geoLocationRequestEnabled = YES;
}

+ (void)disableGeoLocationDefaultRequest {
    KCLogInfo(@"Disabling Geo Location Request");
    geoLocationRequestEnabled = NO;
}

- (void)clearAllEvents {
    [self.store deleteAllEvents];
}

+ (void)clearAllEvents {
    [self.sharedClient clearAllEvents];
}

- (void)clearAllQueries {
    [self.store deleteAllQueries];
}

+ (void)clearAllQueries {
    [self.sharedClient clearAllQueries];
}

- (KIODBStore *)getDBStore {
    return self.store;
}

+ (KIODBStore *)getDBStore {
    return self.sharedClient.store;
}

- (instancetype)initWithNetwork:(KIONetwork *)network andStore:(KIODBStore *)store andUploader:(KIOUploader *)uploader {
    self = [super init];

    if (self) {
        // log the current version number
        KCLogInfo(@"KeenClient-iOS %@", kKeenSdkVersion);

        self.network = network;
        self.store = store;
        self.uploader = uploader;

        [self refreshCurrentLocation];

        // use global concurrent dispatch queue to run queries in parallel
        self.queryQueue = dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }

    return self;
}

- (id)initWithProjectID:(NSString *)projectID
            andWriteKey:(NSString *)writeKey
             andReadKey:(NSString *)readKey
             andNetwork:(KIONetwork *)network
               andStore:(KIODBStore *)store
            andUploader:(KIOUploader *)uploader {
    if (projectID == nil || projectID.length <= 0) {
        KCLogError(@"You must provide a projectID.");
        return nil;
    }

    if (writeKey && writeKey.length <= 0) {
        KCLogError(@"Your writeKey cannot be an empty string.");
        return nil;
    }

    if (readKey && readKey.length <= 0) {
        KCLogError(@"Your readKey cannot be an empty string.");
        return nil;
    }

    self = [self initWithNetwork:network andStore:store andUploader:uploader];

    if (self) {
        KeenClientConfig *config =
            [[KeenClientConfig alloc] initWithProjectID:projectID andWriteKey:writeKey andReadKey:readKey];
        if (config) {
            self.config = config;
        } else {
            self = nil;
        }
    }

    return self;
}

- (instancetype)init {
    return [self initWithNetwork:[KIONetwork sharedInstance]
                        andStore:[KIODBStore sharedInstance]
                     andUploader:[KIOUploader sharedInstance]];
}

- (id)initWithProjectID:(NSString *)projectID andWriteKey:(NSString *)writeKey andReadKey:(NSString *)readKey {
    return [self initWithProjectID:projectID
                       andWriteKey:writeKey
                        andReadKey:readKey
                        andNetwork:[KIONetwork sharedInstance]
                          andStore:[KIODBStore sharedInstance]
                       andUploader:[KIOUploader sharedInstance]];
}

#pragma mark - Get a shared client

+ (KeenClient *)sharedClientWithProjectID:(NSString *)projectID
                              andWriteKey:(NSString *)writeKey
                               andReadKey:(NSString *)readKey {
    KeenClient *client = nil;

    self.sharedClient.config =
        [[KeenClientConfig alloc] initWithProjectID:projectID andWriteKey:writeKey andReadKey:readKey];
    if (self.sharedClient.config) {
        client = self.sharedClient;
    }

    return client;
}

+ (KeenClient *)sharedClient {
    static KeenClient *s_sharedClient;

    // This black magic ensures this block
    // is dispatched only once over the lifetime
    // of the program. It's nice because
    // this works even when there's a race
    // between threads to create the object,
    // as both threads will wait synchronously
    // for the block to complete.
    static dispatch_once_t predicate = {0};
    dispatch_once(&predicate, ^{
        s_sharedClient = [KeenClient new];
    });

    return s_sharedClient;
}

#pragma mark - Geo stuff

- (void)refreshCurrentLocation {
    if (geoLocationEnabled == NO) {
        KCLogInfo(@"Geo Location is disabled.");
        return;
    }

    KCLogInfo(@"Geo Location is enabled.");
    // set up the location manager
    if (self.locationManager == nil && [CLLocationManager locationServicesEnabled]) {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
    }

    // Provide appropriate authorization for location services

    if (self.locationManager) {
        // If location services are already authorized, then just start monitoring.
        CLAuthorizationStatus clAuthStatus = [CLLocationManager authorizationStatus];
        if ([KeenClient isLocationAuthorized:clAuthStatus]) {
            [self startMonitoringLocation];
        }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        // Else, try and request permission for that.
        else if (geoLocationRequestEnabled &&
                 [self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            // allow explicit control over the type of authorization
            if (authorizedGeoLocationAlways) {
                [self.locationManager requestAlwaysAuthorization];
            } else if (authorizedGeoLocationWhenInUse) {
                [self.locationManager requestWhenInUseAuthorization];
            } else if (!authorizedGeoLocationAlways && !authorizedGeoLocationWhenInUse) {
                // default to when in use because it is the least invasive authorization
                [self.locationManager requestWhenInUseAuthorization];
            }
        }
#endif
    }
}

- (void)startMonitoringLocation {
    [self.locationManager startUpdatingLocation];
    KCLogInfo(@"Started location manager.");
}

+ (BOOL)isLocationAuthorized:(CLAuthorizationStatus)status {
#if TARGET_OS_IOS
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        return YES;
    }
#elif TARGET_OS_MAC
    if (status == kCLAuthorizationStatusAuthorized) {
        return YES;
    }
#endif
    return NO;
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    // If it's a relatively recent event, turn off updates to save power
    NSDate *eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if ((int)fabs(howRecent) < 15.0) {
        KCLogInfo(
            @"latitude %+.6f, longitude %+.6f\n", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
        self.currentLocation = newLocation;
        // got the location, now stop checking
        [self.locationManager stopUpdatingLocation];
        KCLogInfo(@"Done finding location");
    } else {
        KCLogInfo(@"Event wasn't recent enough: %+.2d", (int)fabs(howRecent));
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if ([KeenClient isLocationAuthorized:status]) {
        [self startMonitoringLocation];
    }
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    KCLogError(@"locationManager-didFailWithError: %@", [error localizedDescription]);
}

#pragma mark - Add events

- (BOOL)validateEventCollection:(NSString *)eventCollection error:(NSError **)anError {
    NSString *errorMessage;

    if ([eventCollection hasPrefix:@"$"]) {
        errorMessage = @"An event collection name cannot start with the dollar sign ($) character.";
        return [KIOUtil handleError:anError withErrorMessage:errorMessage];
    }
    if ([eventCollection length] > 64) {
        errorMessage = @"An event collection name cannot be longer than 64 characters.";
        return [KIOUtil handleError:anError withErrorMessage:errorMessage];
    }
    return YES;
}

- (BOOL)validateEvent:(NSDictionary *)event withDepth:(NSUInteger)depth error:(NSError **)anError {
    NSString *errorMessage;

    if (depth == 0) {
        if (!event || event.count == 0) {
            errorMessage = @"You must specify a non-null, non-empty event.";
            return [KIOUtil handleError:anError withErrorMessage:errorMessage];
        }
        id keenObject = [event objectForKey:@"keen"];
        if (keenObject && ![keenObject isKindOfClass:[NSDictionary class]]) {
            errorMessage = @"An event's root-level property named 'keen' must be a dictionary.";
            return [KIOUtil handleError:anError withErrorMessage:errorMessage];
        }
    }

    for (NSString *key in event) {
        // validate keys
        if ([key containsString:@"."]) {
            errorMessage = @"An event cannot contain a property with the period (.) character in it.";
            return [KIOUtil handleError:anError withErrorMessage:errorMessage];
        }
        if ([key hasPrefix:@"$"]) {
            errorMessage = @"An event cannot contain a property that starts with the dollar sign ($) character in it.";
            return [KIOUtil handleError:anError withErrorMessage:errorMessage];
        }
        if ([key length] > 256) {
            errorMessage = @"An event cannot contain a property longer than 256 characters.";
            return [KIOUtil handleError:anError withErrorMessage:errorMessage];
        }

        // now validate values
        id value = [event objectForKey:key];
        if ([value isKindOfClass:[NSString class]]) {
            // strings can't be longer than 10k
            if ([value length] > 10000) {
                errorMessage = @"An event cannot contain a property value longer than 10,000 characters.";
                return [KIOUtil handleError:anError withErrorMessage:errorMessage];
            }
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            if (![self validateEvent:value withDepth:depth + 1 error:anError]) {
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)addEvent:(NSDictionary *)event toEventCollection:(NSString *)eventCollection error:(NSError **)error {
    return [self addEvent:event withKeenProperties:nil toEventCollection:eventCollection error:error];
}

- (BOOL)addEvent:(NSDictionary *)event
    withKeenProperties:(KeenProperties *)keenProperties
     toEventCollection:(NSString *)eventCollection
                 error:(NSError **)error {
    // make sure the write key has been set - can't do anything without that
    if (self.config.writeKey == nil || self.config.writeKey.length <= 0) {
        [NSException raise:@"KeenNoWriteKeyProvided"
                    format:@"You tried to add an event without setting a write key, please set one!"];
    }

    // don't do anything if the event itself or the event collection name are invalid somehow.
    if (![self validateEventCollection:eventCollection error:error]) {
        return NO;
    }
    if (![self validateEvent:event withDepth:0 error:error]) {
        return NO;
    }

    KCLogVerbose(@"Adding event to collection: %@", eventCollection);

    // create the body of the event we'll send off. first copy over all keys from the global properties
    // dictionary, then copy over all the keys from the global properties block, then copy over all the
    // keys from the user-defined event.
    NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
    if (self.globalPropertiesDictionary) {
        [newEvent addEntriesFromDictionary:self.globalPropertiesDictionary];
    }
    if (self.globalPropertiesBlock) {
        NSDictionary *globalProperties = self.globalPropertiesBlock(eventCollection);
        if (globalProperties) {
            [newEvent addEntriesFromDictionary:globalProperties];
        }
    }
    [newEvent addEntriesFromDictionary:event];
    event = newEvent;

    // now make sure that we haven't hit the max number of events in this collection already
    NSUInteger eventCount = [self.store getTotalEventCountWithProjectID:self.config.projectID];

    // We add 1 because we want to know if this will push us over the limit
    if (eventCount + 1 > self.maxEventsPerCollection) {
        // need to age out old data so the cache doesn't grow too large
        KCLogWarn(@"Too many events in cache for %@, aging out old data.", eventCollection);
        KCLogWarn(@"Count: %lu and Max: %lu", (unsigned long)eventCount, (unsigned long)self.maxEventsPerCollection);
        [self.store deleteEventsFromOffset:[NSNumber numberWithUnsignedInteger:eventCount - self.numberEventsToForget]];
    }

    if (!keenProperties) {
        KeenProperties *newProperties = [KeenProperties new];
        keenProperties = newProperties;
    }
    if (geoLocationEnabled && self.currentLocation && keenProperties.location == nil) {
        keenProperties.location = self.currentLocation;
    }

    // this is the event we'll actually write
    NSMutableDictionary *eventToWrite = [NSMutableDictionary dictionaryWithDictionary:event];

    // either set "keen" only from keen properties or merge in
    NSDictionary *originalKeenDict = [eventToWrite objectForKey:@"keen"];
    if (originalKeenDict) {
        // have to merge
        NSMutableDictionary *keenDict = [KIOUtil handleInvalidJSONInObject:keenProperties];
        [keenDict addEntriesFromDictionary:originalKeenDict];
        [eventToWrite setObject:keenDict forKey:@"keen"];
    } else {
        // just set it directly
        [eventToWrite setObject:keenProperties forKey:@"keen"];
    }

    NSError *serializationError;
    NSData *jsonData = [KIOUtil serializeEventToJSON:eventToWrite error:&serializationError];
    if (serializationError) {
        return [KIOUtil handleError:error
                   withErrorMessage:[NSString stringWithFormat:@"An error occurred when serializing event to JSON: %@",
                                                               [serializationError localizedDescription]]
                    underlyingError:serializationError];
    }

    // write JSON to store
    [self.store addEvent:jsonData collection:eventCollection projectID:self.config.projectID];

    // log the event
    KCLogVerbose(@"Event: %@", eventToWrite);

    return YES;
}

- (void)importFileData {
    [KIOFileStore importFileDataWithProjectID:self.config.projectID];
}

- (void)uploadWithFinishedBlock:(void (^)())block {
    [self.uploader uploadEventsForConfig:self.config completionHandler:block];
}

#pragma mark - Querying

#pragma mark Async methods

- (void)runAsyncQuery:(KIOQuery *)keenQuery block:(AnalysisCompletionBlock)block {
    [self runAsyncQuery:keenQuery completionHandler:block];
}

- (void)runAsyncQuery:(KIOQuery *)keenQuery completionHandler:(AnalysisCompletionBlock)completionHandler {
    dispatch_async(self.queryQueue, ^{
        [self.network runQuery:keenQuery
                        config:self.config
             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                 // we're done querying, call the main queue and execute the block
                 dispatch_async(dispatch_get_main_queue(), ^{
                     // run the user-specific block (if there is one)
                     if (completionHandler) {
                         KCLogVerbose(@"Running user-specified block.");
                         completionHandler(data, response, error);
                     }
                 });
             }];
    });
}

- (AnalysisCompletionBlock)mainQueueCompletionHandler:(AnalysisCompletionBlock)completionHandler {
    return ^(NSData *data, NSURLResponse *response, NSError *error) {
        // If there's a completion handler, call it from the main queue
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // run the user-specific block
                completionHandler(data, response, error);
            });
        }
    };
}

- (void)runAsyncMultiAnalysisWithQueries:(NSArray *)keenQueries block:(AnalysisCompletionBlock)block {
    [self runAsyncMultiAnalysisWithQueries:keenQueries completionHandler:block];
}

- (void)runAsyncMultiAnalysisWithQueries:(NSArray *)keenQueries
                       completionHandler:(AnalysisCompletionBlock)completionHandler {
    dispatch_async(self.queryQueue, ^{
        [self.network runMultiAnalysisWithQueries:keenQueries
                                           config:self.config
                                completionHandler:[self mainQueueCompletionHandler:completionHandler]];
    });
}

- (void)runAsyncSavedAnalysis:(NSString *)queryName completionHandler:(AnalysisCompletionBlock)completionHandler {
    dispatch_async(self.queryQueue, ^{
        [self.network runSavedAnalysis:queryName
                                config:self.config
                     completionHandler:[self mainQueueCompletionHandler:completionHandler]];
    });
}

- (void)runAsyncDatasetQuery:(NSString *)datasetName
                  indexValue:(NSString *)indexValue
                   timeframe:(NSString *)timeframe
           completionHandler:(AnalysisCompletionBlock)completionHandler {
    dispatch_async(self.queryQueue, ^{
        [self.network runDatasetQuery:datasetName
                           indexValue:indexValue
                            timeframe:timeframe
                               config:self.config
                    completionHandler:[self mainQueueCompletionHandler:completionHandler]];
    });
}

- (BOOL)setProxy:(NSString *)host port:(NSNumber *)port {
    return [self.network setProxy:host port:port];
}

- (NSString *)getProxyHost {
    return self.network.proxyHost;
}

- (NSNumber *)getProxyPort {
    return self.network.proxyPort;
}

- (void)runQuery:(KIOQuery *)keenQuery completionHandler:(AnalysisCompletionBlock)completionHandler {
    [self.network runQuery:keenQuery config:self.config completionHandler:completionHandler];
}

- (void)runMultiAnalysisWithQueries:(NSArray *)keenQueries
                  completionHandler:(AnalysisCompletionBlock)completionHandler {
    [self.network runMultiAnalysisWithQueries:keenQueries config:self.config completionHandler:completionHandler];
}

+ (NSString *)sdkVersion {
    return kKeenSdkVersion;
}

#pragma mark - To make testing easier

- (NSUInteger)maxEventsPerCollection {
    if (self.isRunningTests) {
        return 5;
    }
    return kKeenMaxEventsPerCollection;
}

- (NSUInteger)numberEventsToForget {
    if (self.isRunningTests) {
        return 2;
    }
    return kKeenNumberEventsToForget;
}

@end
