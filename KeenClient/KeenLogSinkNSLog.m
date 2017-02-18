//
//  KeenLogSinkNSLog.m
//  KeenClient
//
//  Created by Brian Baumhover on 2/16/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenLogSinkNSLog.h"

@implementation KeenLogSinkNSLog

- (void)logMessageWithLevel:(KeenLogLevel)msgLevel andMessage:(NSString*)message {
    NSString* logPrefix;
    switch (msgLevel) {
        case KLL_ERROR:
            logPrefix = @"E:";
            break;
        case KLL_WARNING:
            logPrefix = @"W:";
            break;
        case KLL_INFO:
            logPrefix = @"I:";
            break;
        case KLL_VERBOSE:
            logPrefix = @"V:";
            break;
    }
    NSLog(@"%@%@", logPrefix, message);
}

- (void)onRemoved {
    // do nothing
}

@end
