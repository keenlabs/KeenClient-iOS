//
//  KeenClient.h
//  KeenClient
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

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
 Call this to retrieve the managed instance of KeenClient and set its project ID and auth token
 to the given parameters.
 
 You'll generally want to call this the first time you ask for the shared client.  Once you've called
 this, you can simply call [KeenClient sharedClient] afterwards.
 
 @param projectId The ID of your project.
 @param authToken The authorization token for your project.
 @returns A managed instance of KeenClient, or nil if projectId or authToken are invalid.
 */
+ (KeenClient *)sharedClientWithProjectId:(NSString *)projectId andAuthToken:(NSString *)authToken;

/**
 Call this to retrieve the managed instance of KeenClient.
 
 If you only have to use a single Keen project, just use this.
 
 @returns A managed instance of KeenClient, or nil if you haven't called [KeenClient sharedClientWithProjectId:andAuthToken:].
 */
+ (KeenClient *)sharedClient;

/**
 Call this if your code needs to use more than one Keen project and auth token.  By convention, if you
 call this, you're responsible for releasing the returned instance once you're finished with it.
 
 Otherwise, just use [KeenClient sharedClient].
 
 @param projectId The ID of your project.
 @param authToken The authorization token for your project.
 @returns An initialized instance of KeenClient.
 */
- (id)initWithProjectId:(NSString *)projectId andAuthToken:(NSString *)authToken;

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
 Call this whenever you want to upload all the events captured so far.  This will spawn a low
 priority background thread and process all required HTTP requests.
 
 If an upload fails, the events will be saved for a later attempt.
 
 If a particular event is invalid, the event will be dropped from the queue and the failure message
 will be logged.
 
 @param block The block to be executed once uploading is finished, regardless of whether or not the upload succeeded.
 */
- (void)uploadWithFinishedBlock:(void (^)())block;

@end
