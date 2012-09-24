//
//  KeenClient.h
//  KeenClient
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>


// defines KEEN_DEBUG and the KCLog macros
#define KEEN_DEBUG

#ifdef KEEN_DEBUG
#define KCLog(...) NSLog(__VA_ARGS__)
#else
#define KCLog(...)
#endif

// defines a type for the block we'll use with our global properties
typedef NSDictionary* (^KeenGlobalPropertiesBlock)(NSString *eventName);

/**
 KeenClient has class methods to return managed instances of itself and instance methods
 to collect new events and upload them through the keen API.
 
 Example usage:
 
    [KeenClient sharedClientWithProjectId:@"my_id" andAuthToken:@"my_token"];
    NSDictionary *myEvent = [NSDictionary dictionary];
    [[KeenClient sharedClient] addEvent:myEvent toCollection:@"purchases"];
    [[KeenClient sharedClient] uploadWithFinishedBlock:nil];
 */
@interface KeenClient : NSObject

/**
 This Objective-C property represents the Keen Global Properties dictionary for this instance of the
 KeenClient. The dictionary is used every time an event is added to an event collection.
 
 Keen Global Properties are properties which are sent with EVERY event. For example, you may wish to always
 capture static information like user ID, app version, etc.
 
 Every time an event is added to an event collection, the SDK will check to see if this property is defined.
 If it is, the SDK will copy all the properties from the global properties into the newly added event.
 
 Note that because this is just a dictionary, it's much more difficult to create DYNAMIC global properties.
 It also doesn't support per-collection properties. If either of these use cases are important to you, please use 
 the Objective-C property globalPropertiesBlock.
 
 Also note that the Keen properties defined in the globalPropertiesBlock take precendence over the properties
 defined in the globalPropertiesDictionary, and that the Keen Properties defined in each individual event take
 precedence over either of the Global Properties.
 
 Example usage:
 
    KeenClient *client = [KeenClient sharedClient];
    client.globalPropertiesDictionary = @{@"some_standard_key": @"some_standard_value"};
 
 */
@property (nonatomic, retain) NSDictionary *globalPropertiesDictionary;

/**
 This Objective-C property represents the Keen Global Properties block for this instance of the KeenClient. 
 The block is invoked every time an event is added to an event collection.
 
 Keen Global Properties are properties which are sent with EVERY event. For example, you may wish to always
 capture device information like OS version, handset type, orientation, etc.
 
 The block is invoked every time an event is added to an event collection. It takes as a parameter a single
 NSString, which is the name of the event collection the event's being added to. The user is responsible
 for returning an NSDictionary which represents the global properties for this particular event collection.
 
 Note that because we use a block, you can create DYNAMIC global properties. For example, if you want to
 capture device orientation, then your block can ask the device for its current orientation and then construct
 the NSDictionary. If your global properties aren't dynamic, then just return the same NSDictionary every time.
 
 Also note that the Keen properties defined in the globalPropertiesBlock take precendence over the properties
 defined in the globalPropertiesDictionary, and that the Keen Properties defined in each individual event take
 precedence over either of the Global Properties.
 
 Example usage:
 
    KeenClient *client = [KeenClient sharedClient];
    client.globalPropertiesBlock = ^NSDictionary *(NSString *eventName) {
        if ([eventName isEqualToString:@"apples"]) {
            return @{ @"color": @"red" };
        } else if ([eventName isEqualToString:@"pears"]) {
            return @{ @"color": @"green" };
        } else {
            return nil;
        }
    };
 
 */
@property (nonatomic, copy) KeenGlobalPropertiesBlock globalPropertiesBlock;

/**
 Call this to retrieve the managed instance of KeenClient and set its project ID and auth token
 to the given parameters.
 
 You'll generally want to call this the first time you ask for the shared client.  Once you've called
 this, you can simply call [KeenClient sharedClient] afterwards.
 
 @param projectId The ID of your project.
 @param authToken The authorization token for your project.
 @return A managed instance of KeenClient, or nil if projectId or authToken are invalid.
 */
+ (KeenClient *)sharedClientWithProjectId:(NSString *)projectId andAuthToken:(NSString *)authToken;

/**
 Call this to retrieve the managed instance of KeenClient.
 
 If you only have to use a single Keen project, just use this.
 
 @return A managed instance of KeenClient, or nil if you haven't called [KeenClient sharedClientWithProjectId:andAuthToken:].
 */
+ (KeenClient *)sharedClient;

/**
 Call this if your code needs to use more than one Keen project and auth token.  By convention, if you
 call this, you're responsible for releasing the returned instance once you're finished with it.
 
 Otherwise, just use [KeenClient sharedClient].
 
 @param projectId The ID of your project.
 @param authToken The authorization token for your project.
 @return An initialized instance of KeenClient.
 */
- (id)initWithProjectId:(NSString *)projectId andAuthToken:(NSString *)authToken;

/**
 Call this to set the global properties block for this instance of the KeenClient. The block is invoked
 every time an event is added to an event collection.
 
 Global properties are properties which are sent with EVERY event. For example, you may wish to always
 capture device information like OS version, handset type, orientation, etc.
 
 The block is invoked every time an event is added to an event collection. It takes as a parameter a single
 NSString, which is the name of the event collection the event's being added to. The user is responsible
 for returning an NSDictionary which represents the global properties for this particular event collection.
 
 Note that because we use a block, you can create DYNAMIC global properties. For example, if you want to
 capture device orientation, then your block can ask the device for its current orientation and then construct
 the NSDictionary. If your global properties aren't dynamic, then just return the same NSDictionary every time.
 
 @param block The block which is invoked any time an event is added to an event collection.
 */
- (void)setGlobalPropertiesBlock:(NSDictionary * (^)(NSString *eventName))block;

/**
 Call this any time you want to add an event that will eventually be sent to the keen.io server.
 
 The event will be stored on the local file system until you decide to upload (usually this will happen
 in your application delegate right before your app goes into the background, but it could be any time).
 
 @param event An NSDictionary that consists of key/value pairs.  Keen naming conventions apply.  Nested NSDictionaries or NSArrays are acceptable.
 @param collection The collection you want to put this event into.
 @return YES if the event was added, NO if it was not.
 */
- (BOOL)addEvent:(NSDictionary *)event toCollection:(NSString *)collection;

/**
 Call this any time you want to add an event that will eventually be sent to the keen.io server AND you
 want to override defaulte properties (like timestamp).
 
 The event will be stored on the local file system until you decide to upload (usually this will happen
 in your application delegate right before your app goes into the background, but it could be any time).
 
 @param event An NSDictionary that consists of key/value pairs.  Keen naming conventions apply.  Nested NSDictionaries or NSArrays are acceptable.
 @param headerProperties An NSDictionary that consists of key/value pairs to override defaulte properties. ex: "timestamp" -> NSDate
 @param collection The collection you want to put this event into.
 @return YES if the event was added, NO if it was not.
 */
- (BOOL)addEvent:(NSDictionary *)event withHeaderProperties:(NSDictionary *)headerProperties toCollection:(NSString *)collection;

/**
 Call this whenever you want to upload all the events captured so far.  This will spawn a low
 priority background thread and process all required HTTP requests.
 
 If an upload fails, the events will be saved for a later attempt.
 
 If a particular event is invalid, the event will be dropped from the queue and the failure message
 will be logged.
 
 @param block The block to be executed once uploading is finished, regardless of whether or not the upload succeeded.
 */
- (void)uploadWithFinishedBlock:(void (^)())block;

@end
