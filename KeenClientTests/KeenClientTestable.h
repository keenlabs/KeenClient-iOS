//
//  KeenClientTestable.h
//  KeenClient
//
//  Created by Brian Baumhover on 4/27/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KIONetwork.h"
#import "KIOUploader.h"

@interface KeenClient (Testable)

@property KeenClientConfig *config;

@property (nonatomic) KIONetwork *network;

@property (nonatomic) KIODBStore *store;

// If we're running tests.
// TODO: Remove this flag
@property (nonatomic) BOOL isRunningTests;

- (id)initWithProjectID:(NSString *)projectID
            andWriteKey:(NSString *)writeKey
             andReadKey:(NSString *)readKey
             andNetwork:(KIONetwork *)network
               andStore:(KIODBStore *)store
            andUploader:(KIOUploader *)uploader;

@end
