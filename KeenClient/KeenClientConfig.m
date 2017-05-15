//
//  KeenClientConfig.m
//  KeenClient
//
//  Created by Brian Baumhover on 4/27/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenClientConfig.h"
#import "KIOUtil.h"
#import "KeenClient.h"

@implementation KeenClientConfig

- (instancetype)init {
    [NSException raise:@"Method not implemented." format:@"Method not implemented."];
    return nil;
}

- (instancetype)initWithProjectID:(NSString*)projectID
                      andWriteKey:(NSString*)writeKey
                       andReadKey:(NSString*)readKey {
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

    self = [super init];

    if (self) {
        self.projectID = projectID;
        self.writeKey = writeKey;
        self.readKey = readKey;
    }

    return self;
}


@end
