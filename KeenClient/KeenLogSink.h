//
//  KeenLogger.h
//  KeenClient
//
//  Created by Brian Baumhover on 2/16/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

// A given log level will include all
// messages in lower verbosity levels.
// For example, if the log level is set
// to KLL_WARN, messages will log level
// of both KLL_WARN and KLL_ERROR will
// be logged.
typedef NS_ENUM(NSInteger, KeenLogLevel) {
    KeenLogLevelError = 1,
    KeenLogLevelWarning = 2,
    KeenLogLevelInfo = 3,
    KeenLogLevelVerbose = 4
};

//
// If you want logs from KeenClient, implement this protocol, provide it to KeenClient via addLogSink,
// then set the desired log level and enable logging.
//
@protocol KeenLogSink

- (void)logMessageWithLevel:(KeenLogLevel)msgLevel andMessage:(NSString*)message;

// Even after calling KeenClient removeLogSink, a sink will
// receive messages that had already been queued before the call
// to removeLogSink. This callback gives the logger an opportunity
// to do any processing or flushing it needs to do once it
// has actually been removed from the list of loggers.
- (void)onRemoved;

@end
