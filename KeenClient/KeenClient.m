//
//  KeenClient.m
//  KeenClient
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenClient.h"
#import "KeenConstants.h"
#import <CoreLocation/CoreLocation.h>


static KeenClient *sharedClient;
static NSDateFormatter *dateFormatter;
static BOOL geoLocationEnabled = NO;
static BOOL loggingEnabled = NO;

@interface KeenClient ()

// The project ID for this particular client.
@property (nonatomic, retain) NSString *projectId;

// The Write Key for this particular client.
@property (nonatomic, retain) NSString *writeKey;

// The Read Key for this particular client.
@property (nonatomic, retain) NSString *readKey;

// NSLocationManager
@property (nonatomic, retain) CLLocationManager *locationManager;

// How many times the previous timestamp has been used.
@property (nonatomic) NSInteger numTimesTimestampUsed;

// The max number of events per collection.
@property (nonatomic, readonly) NSUInteger maxEventsPerCollection;

// The number of events to drop when aging out a collection.
@property (nonatomic, readonly) NSUInteger numberEventsToForget;

// A dispatch queue used for uploads.
@property (nonatomic) dispatch_queue_t uploadQueue;

// If we're running tests.
@property (nonatomic) Boolean isRunningTests;

/**
 Initializes KeenClient without setting its project ID or API key.
 @returns An instance of KeenClient.
 */
- (id)init;

/**
 Validates that the given project ID is valid.
 @param projectId The Keen project ID.
 @returns YES if project id is valid, NO otherwise.
 */
+ (BOOL)validateProjectId:(NSString *)projectId;

/**
 Validates that the given key is valid.
 @param key The key to check.
 @returns YES if key is valid, NO otherwise.
 */
+ (BOOL)validateKey:(NSString *)key;

/**
 Returns the path to the app's library/cache directory.
 @returns An NSString* that is a path to the app's documents directory.
 */
- (NSString *)cacheDirectory;

/**
 Returns the root keen directory where collection sub-directories exist.
 @returns An NSString* that is a path to the keen root directory.
 */
- (NSString *)keenDirectory;

/**
 Returns the direct child sub-directories of the root keen directory.
 @returns An NSArray* of NSStrings* that are names of sub-directories.
 */
- (NSArray *)keenSubDirectories;

/**
 Returns all the files and directories that are children of the argument path.
 @param path An NSString* that's a fully qualified path to a directory on the file system.
 @returns An NSArray* of NSStrings* that are names of sub-files or directories.
 */
- (NSArray *)contentsAtPath:(NSString *)path;

/**
 Returns the directory for a particular collection where events exist.
 @param collection The collection.
 @returns An NSString* that is a path to the collection directory.
 */
- (NSString *)eventDirectoryForCollection:(NSString *)collection;

/**
 Returns the full path to write an event to.
 @param collection The collection name.
 @param timestamp  The timestamp of the event.
 @returns An NSString* that is a path to the event to be written.
 */
- (NSString *)pathForEventInCollection:(NSString *)collection 
                         WithTimestamp:(NSDate *)timestamp;

/**
 Creates a directory if it doesn't exist.
 @param dirPath The fully qualfieid path to a directory.
 @returns YES if the directory exists at the end of this operation, NO otherwise.
 */
- (BOOL)createDirectoryIfItDoesNotExist:(NSString *)dirPath;

/**
 Writes a particular blob to the given file.
 @param data The data blob to write.
 @param file The fully qualified path to a file.
 @returns YES if the file was successfully written, NO otherwise.
 */
- (BOOL)writeNSData:(NSData *)data 
             toFile:(NSString *)file;

/**
 Sends an event to the server. Internal impl.
 @param data The data to send.
 @param response The response being returned.
 @param error If an error occurred, filled in.  Otherwise nil.
 */
- (NSData *)sendEvents:(NSData *)data 
     returningResponse:(NSURLResponse **)response 
                 error:(NSError **)error;

/**
 Harvests local file system for any events to send to keen service and prepares the payload
 for the API request.
 @param jsonData If successful, this will be filled with the correct JSON data.  Otherwise it is untouched.
 @param eventPaths If successful, this will be filled with a dictionary that maps event types to their paths on the local filesystem.
 */
- (void)prepareJSONData:(NSData **)jsonData 
          andEventPaths:(NSMutableDictionary **)eventPaths;

/**
 Handles the HTTP response from the keen API.  This involves deserializing the JSON response
 and then removing any events from the local filesystem that have been handled by the keen API.
 @param response The response from the server.
 @param responseData The data returned from the server.
 @param eventPaths A dictionary that maps events to their paths on the file system.
 */
- (void)handleAPIResponse:(NSURLResponse *)response 
                  andData:(NSData *)responseData 
            forEventPaths:(NSDictionary *)eventPaths;

/**
 Converts an NSDate* instance into a correctly formatted ISO-8601 compatible string.
 @param date The NSData* instance to convert.
 @returns An ISO-8601 compatible string representation of the date parameter.
 */
- (id)convertDate:(id)date;

/**
 Fills the error object with the given message appropriately.
 */
- (void) handleError:(NSError **)error withErrorMessage:(NSString *)errorMessage;
    
@end

@implementation KeenClient

@synthesize projectId=_projectId;
@synthesize writeKey=_writeKey;
@synthesize readKey=_readKey;
@synthesize locationManager=_locationManager;
@synthesize currentLocation=_currentLocation;
@synthesize numTimesTimestampUsed=_numTimesTimestampUsed;
@synthesize isRunningTests=_isRunningTests;
@synthesize globalPropertiesDictionary=_globalPropertiesDictionary;
@synthesize globalPropertiesBlock=_globalPropertiesBlock;
@synthesize uploadQueue;

# pragma mark - Class lifecycle

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
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        [dateFormatter setTimeZone:timeZone];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    }
}

+ (void)disableLogging {
    loggingEnabled = NO;
}

+ (void)enableLogging {
    loggingEnabled = YES;
}

+ (Boolean)isLoggingEnabled {
    return loggingEnabled;
}

+ (void)enableGeoLocation {
    KCLog(@"Enabling Geo Location");
    geoLocationEnabled = YES;
}

+ (void)disableGeoLocation {
    KCLog(@"Disabling Geo Location");
    geoLocationEnabled = NO;
}

- (id)init {
    self = [super init];
    
    [self refreshCurrentLocation];
    
    self.uploadQueue = dispatch_queue_create("io.keen.uploader", DISPATCH_QUEUE_SERIAL);
    dispatch_retain(self.uploadQueue);
    
    return self;
}

+ (BOOL)validateProjectId:(NSString *)projectId {
    // validate that project ID is acceptable
    if (!projectId || [projectId length] == 0) {
        return NO;
    }
    return YES;
}

+ (BOOL)validateKey:(NSString *)key {
    // for now just use the same rules as project ID
    return [KeenClient validateProjectId:key];
}

- (id)initWithProjectId:(NSString *)projectId andWriteKey:(NSString *)writeKey andReadKey:(NSString *)readKey {
    if (![KeenClient validateProjectId:projectId]) {
        return nil;
    }
    
    self = [self init];
    if (self) {
        self.projectId = projectId;
        if (writeKey) {
            if (![KeenClient validateKey:writeKey]) {
                return nil;
            }
            self.writeKey = writeKey;
        }
        if (readKey) {
            if (![KeenClient validateKey:readKey]) {
                return nil;
            }
            self.readKey = readKey;
        }
    }

    return self;
}

- (void)dealloc {
    // nil out the properties which we've retained (which will release them)
    self.projectId = nil;
    self.writeKey = nil;
    self.readKey = nil;
    self.locationManager = nil;
    self.currentLocation = nil;
    self.globalPropertiesDictionary = nil;
    // explicitly release the properties which we've copied
    [self.globalPropertiesBlock release];
    dispatch_release(self.uploadQueue);
    [super dealloc];
}

# pragma mark - Get a shared client

+ (KeenClient *)sharedClientWithProjectId:(NSString *)projectId andWriteKey:(NSString *)writeKey andReadKey:(NSString *)readKey {
    if (!sharedClient) {
        sharedClient = [[KeenClient alloc] init];
    }
    if (![KeenClient validateProjectId:projectId]) {
        return nil;
    }
    sharedClient.projectId = projectId;
    
    if (writeKey) {
        // only validate a non-nil value
        if (![KeenClient validateKey:writeKey]) {
            return nil;
        }
    }
    sharedClient.writeKey = writeKey;
    
    if (readKey) {
        // only validate a non-nil value
        if (![KeenClient validateKey:readKey]) {
            return nil;
        }
    }
    sharedClient.readKey = readKey;
    
    return sharedClient;
}

+ (KeenClient *)sharedClient {
    if (!sharedClient) {
        sharedClient = [[KeenClient alloc] init];
    }
    if (![KeenClient validateProjectId:sharedClient.projectId]) {
        KCLog(@"sharedClient requested before registering project ID!");
        return nil;
    }
    return sharedClient;
}

# pragma mark - Geo stuff

- (void)refreshCurrentLocation {
    // only do this if geo is enabled
    if (geoLocationEnabled == YES) {
        KCLog(@"Geo Location is enabled.");
        // set up the location manager
        if (self.locationManager == nil) {
            if ([CLLocationManager locationServicesEnabled]) {
                self.locationManager = [[[CLLocationManager alloc] init] autorelease];
                self.locationManager.delegate = self;
            }
        }
        
        // if, at this point, the location manager is ready to go, we can start location services
        if (self.locationManager) {
            [self.locationManager startUpdatingLocation];
            KCLog(@"Started location manager.");
        }
    } else {
        KCLog(@"Geo Location is disabled.");
    }
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    // If it's a relatively recent event, turn off updates to save power
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
        KCLog(@"latitude %+.6f, longitude %+.6f\n",
              newLocation.coordinate.latitude,
              newLocation.coordinate.longitude);
        self.currentLocation = newLocation;
        // got the location, now stop checking
        [self.locationManager stopUpdatingLocation];
        KCLog(@"Done finding location");
    } else {
        KCLog(@"Event wasn't recent enough: %+.2d", abs(howRecent));
    }
}

# pragma mark - Add events

- (Boolean)validateEventCollection:(NSString *)eventCollection error:(NSError **) anError {
    NSString *errorMessage = nil;
    
    if ([eventCollection rangeOfString:@"$"].location == 0) {
        errorMessage = @"An event collection name cannot start with the dollar sign ($) character.";
        [self handleError:anError withErrorMessage:errorMessage];
        return NO;
    }
    if ([eventCollection length] > 64) {
        errorMessage = @"An event collection name cannot be longer than 64 characters.";
        [self handleError:anError withErrorMessage:errorMessage];
        return NO;
    }
    return YES;
}

- (Boolean)validateEvent:(NSDictionary *)event withDepth:(NSUInteger)depth error:(NSError **) anError {
    NSString *errorMessage = nil;
    
    if (depth == 0) {
        if (!event || [event count] == 0) {
            errorMessage = @"You must specify a non-null, non-empty event.";
            [self handleError:anError withErrorMessage:errorMessage];
            return NO;
        }
        id keenObject = [event objectForKey:@"keen"];
        if (keenObject != nil && ![keenObject isKindOfClass:[NSDictionary class]]) {
            errorMessage = @"An event's root-level property named 'keen' must be a dictionary.";
            [self handleError:anError withErrorMessage:errorMessage];
            return NO;
        }
    }
    
    for (NSString *key in event) {
        // validate keys
        if ([key rangeOfString:@"."].location != NSNotFound) {
            errorMessage = @"An event cannot contain a property with the period (.) character in it.";
            [self handleError:anError withErrorMessage:errorMessage];
            return NO;
        }
        if ([key rangeOfString:@"$"].location == 0) {
            errorMessage = @"An event cannot contain a property that starts with the dollar sign ($) character in it.";
            [self handleError:anError withErrorMessage:errorMessage];
            return NO;
        }
        if ([key length] > 256) {
            errorMessage = @"An event cannot contain a property longer than 256 characters.";
            [self handleError:anError withErrorMessage:errorMessage];
            return NO;
        }
        
        // now validate values
        id value = [event objectForKey:key];
        if ([value isKindOfClass:[NSString class]]) {
            // strings can't be longer than 10k
            if ([value length] > 10000) {
                errorMessage = @"An event cannot contain a property value longer than 10,000 characters.";
                [self handleError:anError withErrorMessage:errorMessage];
                return NO;
            }
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            if (![self validateEvent:value withDepth:depth+1 error:anError]) {
                return NO;
            }
        }
    }
    return YES;
}

- (void)addEvent:(NSDictionary *)event toEventCollection:(NSString *)eventCollection error:(NSError **) anError {
    [self addEvent:event withKeenProperties:nil toEventCollection:eventCollection error:anError];
}

- (void)addEvent:(NSDictionary *)event withKeenProperties:(KeenProperties *)keenProperties toEventCollection:(NSString *)eventCollection error:(NSError **) anError {
    // make sure the write key has been set - can't do anything without that
    if (![KeenClient validateKey:self.writeKey]) {
        [NSException raise:@"KeenNoWriteKeyProvided" format:@"You tried to add an event without setting a write key, please set one!"];
    }
    
    // don't do anything if the event itself or the event collection name are invalid somehow.
    if (![self validateEventCollection:eventCollection error:anError]) {
        return;
    }
    if (![self validateEvent:event withDepth:0 error:anError]) {
        return;
    }
    
    KCLog(@"Adding event to collection: %@", eventCollection);
    
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
    
    // make sure the directory we want to write the file to exists
    NSString *dirPath = [self eventDirectoryForCollection:eventCollection];
    // if the directory doesn't exist, create it.
    Boolean success = [self createDirectoryIfItDoesNotExist:dirPath];
    if (!success) {
        KCLog(@"Couldn't access local directory at %@. Event NOT added.", dirPath);
        return;
    }
    // now make sure that we haven't hit the max number of events in this collection already
    NSArray *eventsArray = [self contentsAtPath:dirPath];
    if ([eventsArray count] >= self.maxEventsPerCollection) {
        // need to age out old data so the cache doesn't grow too large
        KCLog(@"Too many events in cache for %@, aging out old data.", eventCollection);
        KCLog(@"Count: %lu and Max: %lu", (unsigned long)[eventsArray count], (unsigned long)self.maxEventsPerCollection);
        
        NSArray *sortedEventsArray = [eventsArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        // delete the eldest
        for (int i=0; i<self.numberEventsToForget; i++) {
            NSString *fileName = [sortedEventsArray objectAtIndex:i];
            NSString *fullPath = [dirPath stringByAppendingPathComponent:fileName];
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error];
            if (error) {
                KCLog(@"Couldn't delete %@ when aging events out of cache!", [error localizedDescription]);
            }
        }
    }
    
    if (!keenProperties) {
        KeenProperties *newProperties = [[[KeenProperties alloc] init] autorelease];
        keenProperties = newProperties;
    }
    if (geoLocationEnabled && self.currentLocation != nil && keenProperties.location == nil) {
        keenProperties.location = self.currentLocation;
    }
    
    // this is the event we'll actually write
    NSMutableDictionary *eventToWrite = [NSMutableDictionary dictionaryWithDictionary:event];
    
    // either set "keen" only from keen properties or merge in
    NSDictionary *originalKeenDict = [eventToWrite objectForKey:@"keen"];
    if (originalKeenDict) {
        // have to merge
        NSMutableDictionary *keenDict = [self handleInvalidJSONInObject:keenProperties];
        [keenDict addEntriesFromDictionary:originalKeenDict];
        [eventToWrite setObject:keenDict forKey:@"keen"];
        
    } else {
        // just set it directly
        [eventToWrite setObject:keenProperties forKey:@"keen"];
    }
    
    NSError *error = nil;
    NSData *jsonData = [self serializeEventToJSON:eventToWrite error:&error];
    if (error) {
        [self handleError:anError
         withErrorMessage:[NSString stringWithFormat:@"An error occurred when serializing event to JSON: %@", [error localizedDescription]]];
        return;
    }
    
    // now figure out the correct filename.
    NSString *fileName = [self pathForEventInCollection:eventCollection WithTimestamp:[NSDate date]];
    
    // write JSON to file system
    [self writeNSData:jsonData toFile:fileName];
    
    // log the event
    if ([KeenClient isLoggingEnabled]) {
        KCLog(@"Event: %@", eventToWrite);
    }
}

- (NSData *)serializeEventToJSON:(NSMutableDictionary *)event error:(NSError **) anError {
    id fixed = [self handleInvalidJSONInObject:event];
    
    if (![NSJSONSerialization isValidJSONObject:fixed]) {
        [self handleError:anError withErrorMessage:@"Event contains an invalid JSON type!"];
        return nil;
    }
    return [NSJSONSerialization dataWithJSONObject:fixed options:0 error:anError];
}

- (NSMutableDictionary *)makeDictionaryMutable:(NSDictionary *)dict {
    return [[dict mutableCopy] autorelease];
}

- (NSMutableArray *)makeArrayMutable:(NSArray *)array {
    return [[array mutableCopy] autorelease];
}

- (id)handleInvalidJSONInObject:(id)value {
    if (!value) {
        return value;
    }
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mutDict = [self makeDictionaryMutable:value];
        NSArray *keys = [mutDict allKeys];
        for (NSString *dictKey in keys) {
            id newValue = [self handleInvalidJSONInObject:[mutDict objectForKey:dictKey]];
            [mutDict setObject:newValue forKey:dictKey];
        }
        return mutDict;
    } else if ([value isKindOfClass:[NSArray class]]) {
        // make sure the array is mutable and then recurse for every element
        NSMutableArray *mutArr = [self makeArrayMutable:value];
        for (NSUInteger i=0; i<[mutArr count]; i++) {
            id arrVal = [mutArr objectAtIndex:i];
            arrVal = [self handleInvalidJSONInObject:arrVal];
            [mutArr setObject:arrVal atIndexedSubscript:i];
        }
        return mutArr;
    } else if ([value isKindOfClass:[NSDate class]]) {
        return [self convertDate:value];
    } else if ([value isKindOfClass:[KeenProperties class]]) {
        KeenProperties *keenProperties = value;
        
        NSString *isoDate = [self convertDate:keenProperties.timestamp];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:isoDate forKey:@"timestamp"];
        
        CLLocation *location = keenProperties.location;
        if (location != nil) {
            NSNumber *longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
            NSNumber *latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
            NSArray *coordinatesArray = [NSArray arrayWithObjects:longitude, latitude, nil];
            NSDictionary *coordinatesDict = [NSDictionary dictionaryWithObject:coordinatesArray forKey:@"coordinates"];
            [dict setObject:coordinatesDict forKey:@"location"];
        }
        
        return dict;
    } else {
        return value;
    }
}

# pragma mark - Uploading

- (void)uploadHelperWithFinishedBlock:(void (^)()) block {
    // only one thread should be doing an upload at a time.
    @synchronized(self) {        
        // get data for the API request we'll make
        NSData *data = nil;
        NSMutableDictionary *eventPaths = nil;
        [self prepareJSONData:&data andEventPaths:&eventPaths];
        if ([data length] > 0 && [eventPaths count] > 0) {
            // then make an http request to the keen server.
            NSURLResponse *response = nil;
            NSError *error = nil;
            NSData *responseData = [self sendEvents:data returningResponse:&response error:&error];
            
            // then parse the http response and deal with it appropriately
            [self handleAPIResponse:response andData:responseData forEventPaths:eventPaths];
        }
        
        // finally, run the user-specific block (if there is one)
        if (block) {
            KCLog(@"Running user-specified block.");
            @try {
                block();
            } @finally {
                Block_release(block);
            }
        }
    }
}

- (void)uploadWithFinishedBlock:(void (^)()) block {
    id copiedBlock = Block_copy(block);
    if (self.isRunningTests) {
        // run upload in same thread if we're in tests
        [self uploadHelperWithFinishedBlock:copiedBlock];
    } else {
        // otherwise do it in the background to not interfere with UI operations
        dispatch_async(self.uploadQueue, ^{
            [self uploadHelperWithFinishedBlock:copiedBlock];
        });
    }
}

- (void)prepareJSONData:(NSData **)jsonData andEventPaths:(NSMutableDictionary **)eventPaths {
    // list all the directories under Keen
    NSArray *directories = [self keenSubDirectories];
    NSString *rootPath = [self keenDirectory];
    
    // set up the request dictionary we'll send out.
    NSMutableDictionary *requestDict = [NSMutableDictionary dictionary];
    
    // declare an error object
    NSError *error = nil;
    
    // create a structure that will hold corresponding paths to all the files
    NSMutableDictionary *fileDict = [NSMutableDictionary dictionary];
    
    // keep track of how many events we'll upload
    NSUInteger eventCount = 0;
    
    // iterate through each directory
    for (NSString *dirName in directories) {
        KCLog(@"Found directory: %@", dirName);
        // list contents of each directory
        NSString *dirPath = [rootPath stringByAppendingPathComponent:dirName];
        NSArray *files = [self contentsAtPath:dirPath];
        
        // set up the array of events that will be used in the request
        NSMutableArray *requestArray = [NSMutableArray array];
        // set up the array of file paths
        NSMutableArray *fileArray = [NSMutableArray array];

        for (NSString *fileName in files) {
            KCLog(@"Found file: %@/%@", dirName, fileName);
            NSString *filePath = [dirPath stringByAppendingPathComponent:fileName];
            // for each file, grab the JSON blob
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            // deserialize it
            error = nil;
            if ([data length] > 0) {
                NSDictionary *eventDict = [NSJSONSerialization JSONObjectWithData:data
                                                                          options:0
                                                                            error:&error];
                if (error) {
                    KCLog(@"An error occurred when deserializing a saved event: %@", [error localizedDescription]);
                    continue;
                }
                // and then add it to the array of events
                [requestArray addObject:eventDict];
                // and also to the array of paths
                [fileArray addObject:filePath];
                // increment event count
                eventCount++;
            }
            else {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
        }
        // and then add the array back to the overall request
        [requestDict setObject:requestArray forKey:dirName];
        // and also to the dictionary of paths
        [fileDict setObject:fileArray forKey:dirName];
    }
    
    // end early if there are no events
    if (eventCount == 0) {
        KCLog(@"Upload called when no events were present, ending early.");
        return;
    }
    
    // now take the request dict and serialize it to JSON
    
    // first serialize the request dict back to a json string
    error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&error];
    if (error) {
        KCLog(@"An error occurred when serializing the final request data back to JSON: %@", 
              [error localizedDescription]);
        // can't do much here.
        return;
    }
    
    *jsonData = data;
    *eventPaths = fileDict;
    
    if ([KeenClient isLoggingEnabled]) {
        KCLog(@"Uploading following events to Keen API: %@", requestDict);
    }
}

- (void)handleAPIResponse:(NSURLResponse *)response 
                  andData:(NSData *)responseData 
            forEventPaths:(NSDictionary *)eventPaths {
    if (!responseData) {
        KCLog(@"responseData was nil for some reason.  That's not great.");
        KCLog(@"response status code: %ld", (long)[((NSHTTPURLResponse *) response) statusCode]);
        return;
    }
    
    NSInteger responseCode = [((NSHTTPURLResponse *)response) statusCode];
    // if the request succeeded, dig into the response to figure out which events succeeded and which failed
    if (responseCode == 200) {
        // deserialize the response
        NSError *error = nil;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData
                                                                     options:0
                                                                       error:&error];
        if (error) {
            NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            KCLog(@"An error occurred when deserializing HTTP response JSON into dictionary.\nError: %@\nResponse: %@", [error localizedDescription], responseString);
            [responseString release];
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
                Boolean deleteFile = YES;
                Boolean success = [[result objectForKey:kKeenSuccessParam] boolValue];
                if (!success) {
                    // grab error code and description
                    NSDictionary *errorDict = [result objectForKey:kKeenErrorParam];
                    NSString *errorCode = [errorDict objectForKey:kKeenNameParam];
                    if ([errorCode isEqualToString:kKeenInvalidCollectionNameError] ||
                        [errorCode isEqualToString:kKeenInvalidPropertyNameError] ||
                        [errorCode isEqualToString:kKeenInvalidPropertyValueError]) {
                        KCLog(@"An invalid event was found.  Deleting it.  Error: %@", 
                              [errorDict objectForKey:kKeenDescriptionParam]);
                        deleteFile = YES;
                    } else {
                        KCLog(@"The event could not be inserted for some reason.  Error name and description: %@, %@", 
                              errorCode, [errorDict objectForKey:kKeenDescriptionParam]);
                        deleteFile = NO;
                    }
                }
                // delete the file if we need to
                if (deleteFile) {
                    NSString *path = [[eventPaths objectForKey:collectionName] objectAtIndex:count];
                    error = nil;
                    
                    // get a file manager
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    
                    [fileManager removeItemAtPath:path error:&error];
                    if (error) {
                        KCLog(@"CRITICAL ERROR: Could not remove event at %@ because: %@", path, 
                              [error localizedDescription]);
                    } else {
                        KCLog(@"Successfully deleted file: %@", path);
                    }
                }
                count++;
            }
        }
    } else {
        // response code was NOT 200, which means something else happened. log this.
        KCLog(@"Response code was NOT 200. It was: %ld", (long)responseCode);
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        KCLog(@"Response body was: %@", responseString);
        [responseString release];
    }            
}

# pragma mark - HTTP request/response management

- (NSData *)sendEvents:(NSData *)data returningResponse:(NSURLResponse **)response error:(NSError **)error {
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/projects/%@/events",
                           kKeenServerAddress, kKeenApiVersion, self.projectId];
    KCLog(@"Sending request to: %@", urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:self.writeKey forHTTPHeaderField:@"Authorization"];
    // TODO check if setHTTPBody also sets content-length
    [request setValue:[NSString stringWithFormat:@"%lud",(unsigned long) [data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:response error:error];
    return responseData;
}

# pragma mark - Directory/path management

- (NSString *)cacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (NSString *)keenDirectory {
    NSString *keenDirPath = [[self cacheDirectory] stringByAppendingPathComponent:@"keen"];
    return [keenDirPath stringByAppendingPathComponent:self.projectId];
}

- (NSArray *)keenSubDirectories {
    return [self contentsAtPath:[self keenDirectory]];
}

- (NSArray *)contentsAtPath:(NSString *) path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        KCLog(@"An error occurred when listing directory (%@) contents: %@", path, [error localizedDescription]);
        return nil;
    }
    return files;
}

- (NSString *)eventDirectoryForCollection:(NSString *)collection {
    return [[self keenDirectory] stringByAppendingPathComponent:collection];
}

- (NSString *)pathForEventInCollection:(NSString *)collection WithTimestamp:(NSDate *)timestamp {
    // get a file manager.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // determine the root of the filename.
    NSString *name = [NSString stringWithFormat:@"%f", [timestamp timeIntervalSince1970]];
    // get the path to the directory where the file will be written
    NSString *directory = [self eventDirectoryForCollection:collection];
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

- (BOOL)createDirectoryIfItDoesNotExist:(NSString *)dirPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // if the directory doesn't exist, create it.
    if (![fileManager fileExistsAtPath:dirPath]) {
        NSError *error = nil;
        Boolean success = [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            KCLog(@"An error occurred when creating directory (%@). Message: %@", dirPath, [error localizedDescription]);
            return NO;
        } else if (!success) {
            KCLog(@"Failed to create directory (%@) but no error was returned.", dirPath);
            return NO;
        }        
    }
    return YES;
}

- (BOOL)writeNSData:(NSData *)data toFile:(NSString *)file {
    // write file atomically so we don't ever have a partial event to worry about.    
    Boolean success = [data writeToFile:file atomically:YES];
    if (!success) {
        KCLog(@"Error when writing event to file: %@", file);
        return NO;
    } else {
        KCLog(@"Successfully wrote event to file: %@", file);
    }
    return YES;
}

- (void) handleError:(NSError **)error withErrorMessage:(NSString *)errorMessage {
    if (error != NULL) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:kKeenErrorDomain code:1 userInfo:userInfo];
        KCLog(@"%@", *error);
    }
}
                    
# pragma mark - NSDate => NSString
                    
- (id)convertDate:(id)date {
    NSString *string = [dateFormatter stringFromDate:date];
    return string;
}

- (id)handleUnsupportedJSONValue:(id)value {
    if ([value isKindOfClass:[NSDate class]]) {
        return [self convertDate:value];
    } else if ([value isKindOfClass:[KeenProperties class]]) {
        KeenProperties *keenProperties = (KeenProperties *)value;
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:keenProperties.timestamp forKey:@"timestamp"];
        CLLocation *location = keenProperties.location;
        if (location != nil) {
            NSNumber *longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
            NSNumber *latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
            NSArray *coordinatesArray = [NSArray arrayWithObjects:longitude, latitude, nil];
            NSDictionary *coordinatesDict = [NSDictionary dictionaryWithObject:coordinatesArray forKey:@"coordinates"];
            [dict setObject:coordinatesDict forKey:@"location"];
        }
        return dict;
    }
    return NULL;
}

# pragma mark - To make testing easier

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
