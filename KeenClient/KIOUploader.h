//
//  KIOUploader.h
//  KeenClient
//
//  Created by Brian Baumhover on 3/22/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KIOUploader : NSObject

/**
 The maximum number of times to try POSTing an event before purging it from the DB.
 */
@property int maxEventUploadAttempts;

// A default shared instance of the object
+ (instancetype)sharedInstance;

// Initialize an instance of the object
- (instancetype)initWithNetwork:(KIONetwork*)network
                       andStore:(KIODBStore*)store;

// Upload events in the store for a given project
- (void)uploadEventsForProjectID:(NSString*)projectID
                    withWriteKey:(NSString*)writeKey
               withFinishedBlock:(void (^)())block;

@end
