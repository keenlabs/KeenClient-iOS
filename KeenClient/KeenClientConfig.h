//
//  KeenClientConfig.h
//  KeenClient
//
//  Created by Brian Baumhover on 4/27/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeenClientConfig : NSObject

- (instancetype)initWithProjectID:(NSString *)projectID andWriteKey:(NSString *)writeKey andReadKey:(NSString *)readKey;

// The project ID for this particular client.
@property (nonatomic, strong) NSString *projectID;

// The Write Key for this particular client.
@property (nonatomic, strong) NSString *writeKey;

// The Read Key for this particular client.
@property (nonatomic, strong) NSString *readKey;

@end
