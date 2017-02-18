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
typedef enum {
    KLL_ERROR = 1,
    KLL_WARNING = 2,
    KLL_INFO = 3,
    KLL_VERBOSE = 4
} KeenLogLevel;

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
