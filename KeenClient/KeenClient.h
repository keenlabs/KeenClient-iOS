//
//  KeenClient.h
//  KeenClient
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeenClient : NSObject {
}

/**
 Call this with your project's authorization token to get a managed instance of KeenClient.
 @param authToken The authorization token for your project.
 @returns A managed instance of KeenClient, or nil if authToken is nil or otherwise invalid.
 */
+ (KeenClient *) getClientForAuthToken: (NSString *) authToken;

/**
 Call this any time you want to add an event that will eventually be sent to the keen.io server.
 @param event      An NSDictionary that consists of key/value pairs.  Keen naming conventions apply.
                   Nested NSDictionaries or NSArrays are acceptable.
 @param collection The collection you want to put this event into.
 @return YES if the event was added, NO if it was not.
 */
- (Boolean) addEvent: (NSDictionary *) event ToCollection: (NSString *) collection;

/**
 Call this whenever you want to upload all the events captured so far.  This will spawn a low
 priority background thread and process all required HTTP requests.
 
 If an upload fails, the events will be saved for a later attempt.
 
 If a particular event is invalid, the event will be dropped from the queue and the failure message
 will be logged.
 */
- (void) upload;

@end
