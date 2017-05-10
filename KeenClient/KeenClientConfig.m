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

- (instancetype)initWithProjectID:(NSString *)projectID
                      andWriteKey:(NSString *)writeKey
                       andReadKey:(NSString *)readKey {
    self = [super init];

    if (nil != self) {
        // Validate key parameters
        if (![KIOUtil validateProjectID:projectID]) {
            KCLogError(@"Invalid projectID: %@", projectID);
            return nil;
        }

        if (nil != writeKey && // only validate a non-nil value
            ![KIOUtil validateKey:writeKey]) {
            KCLogError(@"Invalid writeKey: %@", writeKey);
            return nil;
        }

        if (nil != readKey && // only validate a non-nil value
            ![KIOUtil validateKey:readKey]) {
            KCLogError(@"Invalid readKey: %@", readKey);
            return nil;
        }

        self.projectID = projectID;
        self.writeKey = writeKey;
        self.readKey = readKey;
    }

    return self;
}

@end
