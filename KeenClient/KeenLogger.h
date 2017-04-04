//
//  KeenLogger.h
//  KeenClient
//
//  Created by Brian Baumhover on 2/18/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeenLogSink.h"


@interface KeenLogger : NSObject

/**
 Get the shared logger instance.
 */
+ (KeenLogger*)sharedLogger;

/**
 Call this to disable debug logging. It's disabled by default.
 */
- (void)disableLogging;

/**
 Call this to enable debug logging. If no log sinks have been added,
 a default NSLog logger will automatically be added.
 */
- (void)enableLogging;

/**
 Enable or disable logging to NSLog
 */
- (void)setIsNSLogEnabled:(BOOL)isNSLogEnabled;

/**
 Whether or not NSLog logging is enabled
 */
- (BOOL)isNSLogEnabled;

/**
 Returns whether or not logging is currently enabled.

 @return true if logging is enabled, false if disabled.
 */
- (BOOL)isLoggingEnabled;

/*
 Set the level of logging to dispatch to all sinks.
 */
- (void)setLogLevel:(KeenLogLevel)logLevel;

/**
 Add a log sink
 */
- (void)addLogSink:(id<KeenLogSink>)logger;

/**
 Remove a log sink
 */
- (void)removeLogSink:(id<KeenLogSink>)logger;

/**
 Log a message using registered loggers
 */
- (void)logMessageWithLevel:(KeenLogLevel)msgLevel andMessage:(NSString*)message;

@end
