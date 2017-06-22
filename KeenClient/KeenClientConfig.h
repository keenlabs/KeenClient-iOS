//
//  KeenClientConfig.h
//  KeenClient
//
//  Created by Brian Baumhover on 4/27/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeenClientConfig : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithProjectID:(NSString *)projectID andWriteKey:(NSString *)writeKey andReadKey:(NSString *)readKey;

- (instancetype)initWithProjectID:(NSString *)projectID
                      andWriteKey:(NSString *)writeKey
                       andReadKey:(NSString *)readKey
                  apiUrlAuthority:(NSString *)apiUrlAuthority;

// The project ID for this particular client.
@property (nonatomic) NSString *projectID;

// The Write Key for this particular client.
@property (nonatomic) NSString *writeKey;

// The Read Key for this particular client.
@property (nonatomic) NSString *readKey;

// The URL authority for the API, e.g. "api.keen.io:443"
@property (nonatomic) NSString *apiUrlAuthority;

@end
