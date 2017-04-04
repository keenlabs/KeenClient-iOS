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
        case KeenLogLevelError:
            logPrefix = @"E:";
            break;
        case KeenLogLevelWarning:
            logPrefix = @"W:";
            break;
        case KeenLogLevelInfo:
            logPrefix = @"I:";
            break;
        case KeenLogLevelVerbose:
            logPrefix = @"V:";
            break;
    }
    NSLog(@"%@%@", logPrefix, message);
}

- (void)onRemoved {
    // do nothing
}

@end
