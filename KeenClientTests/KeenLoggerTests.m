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
- (Message *)initWithLogLevel:(KeenLogLevel)level andText:(NSString *)newText;
@property KeenLogLevel logLevel;
@property NSString *text;
@end

@implementation Message

- (Message *)initWithLogLevel:(KeenLogLevel)level andText:(NSString *)newText {
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
@interface TestLogSink : NSObject <KeenLogSink>
@end

@implementation TestLogSink

NSMutableArray *_loggedMessages;
NSCondition *_removalCondition;
BOOL _removed;
BOOL _logToNSLog;

- (instancetype)init {
    return [self initWithLogToNSLog:YES];
}

- (instancetype)initWithLogToNSLog:(BOOL)logToNSLog {
    self = [super init];
    if (nil != self) {
        _loggedMessages = [[NSMutableArray alloc] init];
        _removalCondition = [[NSCondition alloc] init];
        _removed = NO;
        _logToNSLog = logToNSLog;
    }
    return self;
}

- (void)logMessageWithLevel:(KeenLogLevel)msgLevel andMessage:(NSString *)message {
    if (_logToNSLog) {
        NSLog(@"LogSink: %@", message);
    }
    [_loggedMessages addObject:[[Message alloc] initWithLogLevel:msgLevel andText:message]];
}

- (void)onRemoved {
    [_removalCondition lock];
    _removed = YES;
    [_removalCondition signal];
    [_removalCondition unlock];
}

// Wait for a signal that's triggered when the logger is removed.
// We'll use this as a way to see if all messages have been drained and recorded.
- (BOOL)waitForRemoval {
    BOOL wasRemoved = NO;
    [_removalCondition lock];
    if (_removed) {
        wasRemoved = YES;
        [_removalCondition unlock];
    } else {
        if ([_removalCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]]) {
            wasRemoved = _removed;
            [_removalCondition unlock];
        } else {
            wasRemoved = NO;
        }
    }
    return wasRemoved;
}

- (NSArray *)getLoggedMessages {
    return _loggedMessages;
}

@end

@implementation KeenLoggerTests

// For testing, can create a LogSink that is created with the expected messages
// Then, do logging, and remove the logger. Create a signal that will be signaled
// when the logger is removed, then do validation of the received messages to expected
// messages.

// Helper method for logging messages
- (void)logMessages:(NSArray *)messages usingLogger:(KeenLogger *)logger {
    for (Message *message in messages) {
        [logger logMessageWithLevel:message.logLevel andMessage:message.text];
    }
}

// Helper method for checking for correctly logged messages
- (void)verifyLoggedMessages:(NSArray *)actual withExpectedMessages:(NSArray *)expected {
    XCTAssertEqual(actual.count, expected.count, @"Message count wasn't expected number.");
    if (actual.count == expected.count) {
        for (NSUInteger i = 0; i < expected.count; ++i) {
            Message *expectedMsg = [expected objectAtIndex:i];
            Message *actualMsg = [actual objectAtIndex:i];
            XCTAssertEqual(expectedMsg.logLevel, actualMsg.logLevel, @"Log level of message was incorrect.");
            XCTAssertEqualObjects(expectedMsg.text, actualMsg.text, @"Log text of message was incorrect.");
        }
    }
}

- (void)testSimpleLogging {
    NSArray *testMessages = [[NSArray alloc]
        initWithObjects:[[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"], nil];

    KeenLogger *testLogger = [[KeenLogger alloc] init];

    // 1. Add a LogSink
    TestLogSink *testSink = [[TestLogSink alloc] init];
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

- (void)testEnableNSLogLogging {
    [self runNSLogTest:YES];
}

- (void)testDisableNSLogLogging {
    [self runNSLogTest:NO];
}

- (void)runNSLogTest:(BOOL)enableNSLog {
    NSArray *testMessages = [[NSArray alloc]
        initWithObjects:[[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"], nil];
    NSString *expectedMessage = @"E:error message";

    KeenLogger *testLogger = [[KeenLogger alloc] init];

    // 1. Add a LogSink
    TestLogSink *testSink = [[TestLogSink alloc] initWithLogToNSLog:NO];
    [testLogger addLogSink:testSink];

    // 2. Enable logging
    [testLogger enableLogging];

    // 3. Disable or enable NSLog logging
    [testLogger setIsNSLogEnabled:enableNSLog];

    // Create a duplicate of the current stderr file descriptor
    int savedStdErr = dup(STDERR_FILENO);

    // Reopen stderr and point it to a writable temporary file
    FILE *newStderr = freopen("test.log", "w", stderr);
    XCTAssertTrue(newStderr != NULL, @"Failed to open log file for output");

    // 4. log messages
    [self logMessages:testMessages usingLogger:testLogger];

    // Ensure all messages were handled before continuing
    [testLogger removeLogSink:testSink];
    [testSink waitForRemoval];

    // Flush stderr to make sure all messages are written
    fflush(stderr);

    // Reset stderr by duplicating the saved file descriptor to the stderr file descriptor
    dup2(savedStdErr, STDERR_FILENO);
    // Close the saved file descriptor as we're done with it
    close(savedStdErr);
    close(newStderr);

    // 5. verify message was/wasn't logged to NSLog
    const size_t cchMaxStringLength = 256;
    char *pchString = malloc(cchMaxStringLength);
    // Open the file stderr wrote to
    FILE *logOutputFile = fopen("test.log", "r");
    XCTAssertTrue(NULL != logOutputFile, @"Failed to open log output file. error: %d", errno);
    // Read the file contents
    fread(pchString, sizeof(char), cchMaxStringLength - 1, logOutputFile);
    fclose(logOutputFile);
    // Ensure the string is null terminated
    pchString[cchMaxStringLength - 1] = '\0';
    // Create an NSString from the c string
    NSString *loggedString = [NSString stringWithCString:pchString encoding:NSASCIIStringEncoding];
    // Find the expected message in the output
    NSRange expectedMessageRange = [loggedString rangeOfString:expectedMessage];

    if (enableNSLog) {
        XCTAssertTrue(expectedMessageRange.location != NSNotFound, @"Logged message wasn't contained in output.");
    } else {
        XCTAssertTrue(expectedMessageRange.location == NSNotFound, @"Logged message was contained in output.");
    }

    [self verifyLoggedMessages:[testSink getLoggedMessages] withExpectedMessages:testMessages];
}

- (void)testEnableAndDisable {
    NSArray *testMessages = [[NSArray alloc]
        initWithObjects:[[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"], nil];

    KeenLogger *testLogger = [[KeenLogger alloc] init];

    // Add a log sink
    TestLogSink *testSink = [[TestLogSink alloc] init];
    [testLogger addLogSink:testSink];

    // Try logging some messages
    [self logMessages:testMessages usingLogger:testLogger];

    // Verfy no messages received.
    [testLogger removeLogSink:testSink];
    [testSink waitForRemoval];
    XCTAssertEqual(
        0, [testSink getLoggedMessages].count, @"Logging was disabled, so no messages should have been recorded.");

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
    XCTAssertEqual(
        0, [testSink getLoggedMessages].count, @"Logging was disabled, so no messages should have been recorded.");
}

- (void)testLogLevels {
    NSArray *testMessages = [[NSArray alloc]
        initWithObjects:[[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"],
                        [[Message alloc] initWithLogLevel:KeenLogLevelWarning andText:@"warning message"],
                        [[Message alloc] initWithLogLevel:KeenLogLevelInfo andText:@"info message"],
                        [[Message alloc] initWithLogLevel:KeenLogLevelVerbose andText:@"verbose message"],
                        nil];
    NSArray *errorLevelMessages = [[NSArray alloc]
        initWithObjects:[[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"], nil];
    NSArray *warningLevelMessages = [[NSArray alloc]
        initWithObjects:[[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"],
                        [[Message alloc] initWithLogLevel:KeenLogLevelWarning andText:@"warning message"],
                        nil];
    NSArray *infoLevelMessages = [[NSArray alloc]
        initWithObjects:[[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"],
                        [[Message alloc] initWithLogLevel:KeenLogLevelWarning andText:@"warning message"],
                        [[Message alloc] initWithLogLevel:KeenLogLevelInfo andText:@"info message"],
                        nil];
    NSArray *verboseLevelMessages = [[NSArray alloc]
        initWithObjects:[[Message alloc] initWithLogLevel:KeenLogLevelError andText:@"error message"],
                        [[Message alloc] initWithLogLevel:KeenLogLevelWarning andText:@"warning message"],
                        [[Message alloc] initWithLogLevel:KeenLogLevelInfo andText:@"info message"],
                        [[Message alloc] initWithLogLevel:KeenLogLevelVerbose andText:@"verbose message"],
                        nil];

    KeenLogger *testLogger = [[KeenLogger alloc] init];

    // Add a log sink
    TestLogSink *testSink = [[TestLogSink alloc] init];
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
