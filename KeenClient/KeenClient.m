//
//  KeenClient.m
//  KeenClient
//
//  Created by Daniel Kador on 2/8/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenClient.h"

static NSDictionary *clients;

@interface KeenClient () {}

// The authorization token for this particular project.
@property (nonatomic, retain) NSString *token;

/**
 Initializes a KeenClient with the given authToken.
 @param authToken The auth token corresponding to the keen.io project.
 @returns an instance of KeenClient, or nil if authToken is nil or otherwise invalid.
 */
- (id) initWithAuthToken: (NSString *) authToken;
    
@end

@implementation KeenClient

@synthesize token=_token;

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
    }
    
    return self;
}

- (void) dealloc {
    self.token = nil;
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

- (void) addEvent: (NSDictionary *) event ToCollection: (NSString *) collection {
    
}

- (void) upload {
    
}

@end
