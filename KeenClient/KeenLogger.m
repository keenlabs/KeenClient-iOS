//
//  KeenLogger.m
//  KeenClient
//
//  Created by Brian Baumhover on 2/18/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenLogger.h"
#import "KeenLogSinkNSLog.h"

@implementation KeenLogger

BOOL logSinksEnabled;
_Atomic(BOOL) loggingEnabled;
KeenLogLevel logLevel;
NSMutableArray *logSinks;
dispatch_queue_t loggerQueue;


+ (KeenLogger*)sharedLogger {
    static KeenLogger* logger;
    
    // This black magic ensures this block
    // is dispatched only once over the lifetime
    // of the program. It's nice because
    // this works even when there's a race
    // between threads to create the object,
    // as both threads will wait synchronously
    // for the block to complete.
    static dispatch_once_t predicate = {0};
    dispatch_once(&predicate, ^{
        logger = [[KeenLogger alloc] init];
    });
    
    return logger;
}


- (KeenLogger*)init {
    self = [super init];
    
    if (nil != self) {
        // By default we won't enable logging.
        logSinksEnabled = NO;
        loggingEnabled = NO;
        // Default log level is error so we aren't noisy
        logLevel = KLL_ERROR;
        // Create a serial queue for logging messages and manipulating loggers.
        // This will ensure that messages from different threads
        // don't get mixed together, and we don't have to worry
        // about concurrent access when adding and removing loggers
        // since those operations will be dispatched to this queue as well.
        loggerQueue = dispatch_queue_create("io.keen.logger", DISPATCH_QUEUE_SERIAL);
        if (NULL == loggerQueue) {
            // Failed to allocate the queue
            self = nil;
        }
        
        logSinks = [[NSMutableArray alloc] init];
        if (nil == logSinks) {
            // Failed to allocate the array
            self = nil;
        }
    }
    
    return self;
}


- (void)disableLogging {
    loggingEnabled = NO;
    dispatch_async(loggerQueue, ^() {
        // Disable actual logging to sinks
        // on the queue so anything that
        // has already been logged but hasn't
        // been sinked will have the
        // opportunity to do so.
        logSinksEnabled = NO;
    });
}


- (void)enableLogging {
    loggingEnabled = YES;
    dispatch_async(loggerQueue, ^() {
        if ([logSinks count] == 0) {
            // Allocate a default logger if none have
            // been provided.
            [logSinks addObject:[[KeenLogSinkNSLog alloc] init]];
        }
        logSinksEnabled = YES;
    });
}


- (BOOL)isLoggingEnabled {
    return loggingEnabled;
}


- (void)setLogLevel:(KeenLogLevel)level {
    dispatch_async(loggerQueue, ^() {
        logLevel = level;
    });
}


- (void)addLogSink:(id<KeenLogSink>)sink {
    dispatch_async(loggerQueue, ^() {
        [logSinks addObject:sink];
    });
}


- (void)removeLogSink:(id<KeenLogSink>)sink {
    dispatch_async(loggerQueue, ^() {
        [logSinks removeObject:sink];
        [sink onRemoved];
    });
}


- (void)logMessageWithLevel:(KeenLogLevel)msgLevel andMessage:(NSString*)message {
    dispatch_async(loggerQueue, ^() {
        if (logSinksEnabled &&
            msgLevel <= logLevel) {
            for (id<KeenLogSink> sink in logSinks) {
                [sink logMessageWithLevel:msgLevel andMessage:message];
            }
        }
    });
}


@end
