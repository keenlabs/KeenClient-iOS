//
//  KeenLoggerTests.m
//  KeenClient
//
//  Created by Brian Baumhover on 2/18/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenLoggerTests.h"
#import "KeenLogger.h"

//
// Class to store messages we'll log or have logged.
//
@interface Message : NSObject
- (Message*)initWithLogLevel:(KeenLogLevel)level andText:(NSString*)newText;
@property KeenLogLevel logLevel;
@property NSString* text;
@end

@implementation Message

- (Message*)initWithLogLevel:(KeenLogLevel)level andText:(NSString*)newText {
    self = [super init];
    if (nil != self) {
        logLevel = level;
        text = newText;
    }
    return self;
}

@synthesize logLevel;
@synthesize text;

@end

//
// A log sink implementation for testing
//
@interface TestLogSink : NSObject<KeenLogSink>
@end

@implementation TestLogSink

NSMutableArray* loggedMessages;
NSCondition* removalCondition;
BOOL removed;

- (TestLogSink*)init {
    self = [super init];
    if (nil != self) {
        loggedMessages = [[NSMutableArray alloc] init];
        removalCondition = [[NSCondition alloc] init];
        removed = NO;
    }
    return self;
}

- (void)logMessageWithLevel:(KeenLogLevel)msgLevel andMessage:(NSString *)message {
    NSLog(@"LogSink: %@", message);
    [loggedMessages addObject:[[Message alloc] initWithLogLevel:msgLevel andText:message]];
}

- (void)onRemoved {
    [removalCondition lock];
    removed = YES;
    [removalCondition signal];
    [removalCondition unlock];
}

// Wait for a signal that's triggered when the logger is removed.
// We'll use this as a way to see if all messages have been drained and recorded.
- (BOOL)waitForRemoval {
    BOOL wasRemoved = NO;
    [removalCondition lock];
    if (removed) {
        wasRemoved = YES;
        [removalCondition unlock];
    } else {
        if ([removalCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]]) {
            wasRemoved = removed;
            [removalCondition unlock];
        } else {
            wasRemoved = NO;
        }
    }
    return wasRemoved;
}

- (NSArray*)getLoggedMessages {
    return loggedMessages;
}

@end


@implementation KeenLoggerTests

// For testing, can create a LogSink that is created with the expected messages
// Then, do logging, and remove the logger. Create a signal that will be signaled
// when the logger is removed, then do validation of the received messages to expected
// messages.

// Helper method for logging messages
- (void)logMessages:(NSArray*)messages usingLogger:(KeenLogger*)logger {
    for (Message* message in messages) {
        [logger logMessageWithLevel:message.logLevel andMessage:message.text];
    }
}

// Helper method for checking for correctly logged messages
- (void)verifyLoggedMessages:(NSArray*)actual withExpectedMessages:(NSArray*)expected {
    XCTAssertEqual(actual.count, expected.count, @"Message count wasn't expected number.");
    for (NSUInteger i = 0; i < expected.count; ++i) {
        Message* expectedMsg = [expected objectAtIndex:i];
        Message* actualMsg = [actual objectAtIndex:i];
        XCTAssertEqual(expectedMsg.logLevel, actualMsg.logLevel, @"Log level of message was incorrect.");
        XCTAssertEqualObjects(expectedMsg.text, actualMsg.text, @"Log text of message was incorrect.");
    }
}

- (void)testSimpleLogging {
    NSArray* testMessages =
        [[NSArray alloc] initWithObjects:[[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"], nil];

    KeenLogger* testLogger = [[KeenLogger alloc] init];

    // 1. Add a LogSink
    TestLogSink* testSink = [[TestLogSink alloc] init];
    [testLogger addLogSink:testSink];

    // 2. Enable logging
    [testLogger enableLogging];

    // 3. log messages
    [self logMessages:testMessages usingLogger:testLogger];

    // 4. verify message was logged
    [testLogger removeLogSink:testSink];
    [testSink waitForRemoval];
    [self verifyLoggedMessages:[testSink getLoggedMessages] withExpectedMessages:testMessages];
}

- (void)testEnableAndDisable {
    NSArray* testMessages =
        [[NSArray alloc] initWithObjects:[[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"], nil];

    KeenLogger* testLogger = [[KeenLogger alloc] init];

    // Add a log sink
    TestLogSink* testSink = [[TestLogSink alloc] init];
    [testLogger addLogSink:testSink];

    // Try logging some messages
    [self logMessages:testMessages usingLogger:testLogger];

    // Verfy no messages received.
    [testLogger removeLogSink:testSink];
    [testSink waitForRemoval];
    XCTAssertEqual(0, [testSink getLoggedMessages].count, @"Logging was disabled, so no messages should have been recorded.");

    // Add a new log sink
    testSink = [[TestLogSink alloc] init];
    [testLogger addLogSink:testSink];

    // Enable logging
    [testLogger enableLogging];

    // Log more messages
    [self logMessages:testMessages usingLogger:testLogger];

    // Verify messages received
    [testLogger removeLogSink:testSink];
    [testSink waitForRemoval];
    [self verifyLoggedMessages:[testSink getLoggedMessages] withExpectedMessages:testMessages];

    // Disable logging
    [testLogger disableLogging];

    // Add a new log sink
    testSink = [[TestLogSink alloc] init];
    [testLogger addLogSink:testSink];

    // log more messages
    [self logMessages:testMessages usingLogger:testLogger];

    // Verfy no messages received.
    [testLogger removeLogSink:testSink];
    [testSink waitForRemoval];
    XCTAssertEqual(0, [testSink getLoggedMessages].count, @"Logging was disabled, so no messages should have been recorded.");
}

- (void)testLogLevels {
    NSArray* testMessages =
        [[NSArray alloc] initWithObjects:
            [[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"],
            [[Message alloc] initWithLogLevel:KeenLogLevelWarning andText:@"warning message"],
            [[Message alloc] initWithLogLevel:KeenLogLevelInfo andText:@"info message"],
            [[Message alloc] initWithLogLevel:KeenLogLevelVerbose andText:@"verbose message"],
            nil];
    NSArray* errorLevelMessages =
        [[NSArray alloc] initWithObjects:
            [[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"],
            nil];
    NSArray* warningLevelMessages =
        [[NSArray alloc] initWithObjects:
            [[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"],
            [[Message alloc] initWithLogLevel:KeenLogLevelWarning andText:@"warning message"],
            nil];
    NSArray* infoLevelMessages =
        [[NSArray alloc] initWithObjects:
            [[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"],
            [[Message alloc] initWithLogLevel:KeenLogLevelWarning andText:@"warning message"],
            [[Message alloc] initWithLogLevel:KeenLogLevelInfo andText:@"info message"],
            nil];
    NSArray* verboseLevelMessages =
        [[NSArray alloc] initWithObjects:
            [[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"],
            [[Message alloc] initWithLogLevel:KeenLogLevelWarning andText:@"warning message"],
            [[Message alloc] initWithLogLevel:KeenLogLevelInfo andText:@"info message"],
            [[Message alloc] initWithLogLevel:KeenLogLevelVerbose andText:@"verbose message"],
            nil];

    KeenLogger* testLogger = [[KeenLogger alloc] init];

    // Add a log sink
    TestLogSink* testSink = [[TestLogSink alloc] init];
    [testLogger addLogSink:testSink];

    // Enable logging
    [testLogger enableLogging];

    // Default log level is KeenLogLevelError, test that log level
    [self logMessages:testMessages usingLogger:testLogger];

    // Verify messages received
    [testLogger removeLogSink:testSink];
    [testSink waitForRemoval];
    [self verifyLoggedMessages:[testSink getLoggedMessages] withExpectedMessages:errorLevelMessages];

    // Add a new log sink
    testSink = [[TestLogSink alloc] init];
    [testLogger addLogSink:testSink];

    // Log messages
    [testLogger setLogLevel:KeenLogLevelWarning];
    [self logMessages:testMessages usingLogger:testLogger];

    // Verify messages received
    [testLogger removeLogSink:testSink];
    [testSink waitForRemoval];
    [self verifyLoggedMessages:[testSink getLoggedMessages] withExpectedMessages:warningLevelMessages];

    // Add a new log sink
    testSink = [[TestLogSink alloc] init];
    [testLogger addLogSink:testSink];

    // Log messages
    [testLogger setLogLevel:KeenLogLevelInfo];
    [self logMessages:testMessages usingLogger:testLogger];

    // Verify messages received
    [testLogger removeLogSink:testSink];
    [testSink waitForRemoval];
    [self verifyLoggedMessages:[testSink getLoggedMessages] withExpectedMessages:infoLevelMessages];

    // Add a new log sink
    testSink = [[TestLogSink alloc] init];
    [testLogger addLogSink:testSink];

    // Log messages
    [testLogger setLogLevel:KeenLogLevelVerbose];
    [self logMessages:testMessages usingLogger:testLogger];

    // Verify messages received
    [testLogger removeLogSink:testSink];
    [testSink waitForRemoval];
    [self verifyLoggedMessages:[testSink getLoggedMessages] withExpectedMessages:verboseLevelMessages];
}

@end
