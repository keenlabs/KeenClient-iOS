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

BOOL _areLogSinksEnabled;
_Atomic(BOOL) _isLoggingEnabled;
_Atomic(BOOL) _isNSLogEnabled;
KeenLogLevel _logLevel;
NSMutableArray *_logSinks;
dispatch_queue_t _loggerQueue;
KeenLogSinkNSLog* _logSinkNSLog;


+ (KeenLogger *)sharedLogger {
    static KeenLogger *s_logger;

    // This black magic ensures this block
    // is dispatched only once over the lifetime
    // of the program. It's nice because
    // this works even when there's a race
    // between threads to create the object,
    // as both threads will wait synchronously
    // for the block to complete.
    static dispatch_once_t predicate = {0};
    dispatch_once(&predicate, ^{
        s_logger = [[KeenLogger alloc] init];
    });

    return s_logger;
}


- (KeenLogger *)init {
    self = [super init];

    if (self) {
        // By default we won't enable logging.
        _areLogSinksEnabled = NO;
        _isLoggingEnabled = NO;
        // Default log level is error so we aren't noisy
        _logLevel = KeenLogLevelError;
        // Create a serial queue for logging messages and manipulating loggers.
        // This will ensure that messages from different threads
        // don't get mixed together, and we don't have to worry
        // about concurrent access when adding and removing loggers
        // since those operations will be dispatched to this queue as well.
        _loggerQueue = dispatch_queue_create("io.keen.logger", DISPATCH_QUEUE_SERIAL);
        if (_loggerQueue == NULL) {
            // Failed to allocate the queue
            self = nil;
        }

        _logSinks = [NSMutableArray array];
        if (_logSinks == nil) {
            // Failed to allocate the array
            self = nil;
        }

        // Enable NSLog by default
        [self setIsNSLogEnabled:YES];
    }

    return self;
}


- (void)disableLogging {
    _isLoggingEnabled = NO;
    dispatch_async(_loggerQueue, ^() {
        // Disable actual logging to sinks
        // on the queue so anything that
        // has already been logged but hasn't
        // been sinked will have the
        // opportunity to do so.
        _areLogSinksEnabled = NO;
    });
}


- (void)enableLogging {
    _isLoggingEnabled = YES;
    dispatch_async(_loggerQueue, ^() {
        _areLogSinksEnabled = YES;
    });
}


- (void)setIsNSLogEnabled:(BOOL)isNSLogEnabled {
    _isNSLogEnabled = isNSLogEnabled;
    dispatch_async(_loggerQueue, ^() {
        if (isNSLogEnabled) {
            if (nil == _logSinkNSLog) {
                // Create the NSLog logger
                _logSinkNSLog = [KeenLogSinkNSLog new];
            }

            if (!([_logSinks containsObject:_logSinkNSLog])) {
                // Add the NSLog logger to the list of loggers if it hasn't already been added
                [_logSinks addObject:_logSinkNSLog];
            }
        } else {
            // Remove the logger if it has been added
            if (nil != _logSinkNSLog) {
                if ([_logSinks containsObject:_logSinkNSLog]) {
                    [_logSinks removeObject:_logSinkNSLog];
                }

                _logSinkNSLog = nil;
            }
        }
    });
}


- (BOOL)isNSLogEnabled {
    return _isNSLogEnabled;
}


- (BOOL)isLoggingEnabled {
    return _isLoggingEnabled;
}


- (void)setLogLevel:(KeenLogLevel)level {
    dispatch_async(_loggerQueue, ^() {
        _logLevel = level;
    });
}


- (void)addLogSink:(id<KeenLogSink>)sink {
    dispatch_async(_loggerQueue, ^() {
        [_logSinks addObject:sink];
    });
}


- (void)removeLogSink:(id<KeenLogSink>)sink {
    dispatch_async(_loggerQueue, ^() {
        [_logSinks removeObject:sink];
        [sink onRemoved];
    });
}


- (void)logMessageWithLevel:(KeenLogLevel)msgLevel andMessage:(NSString *)message {
    if (YES == _isLoggingEnabled) { // Only bother to dispatch if logging is currently enabled
        dispatch_async(_loggerQueue, ^() {
            if (_areLogSinksEnabled &&
                msgLevel <= _logLevel) {
                for (id<KeenLogSink> sink in _logSinks) {
                    [sink logMessageWithLevel:msgLevel andMessage:message];
                }
            }
        });
    }
}


@end
