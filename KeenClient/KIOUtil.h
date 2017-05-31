//
//  KIOUtil.h
//  KeenClient
//
//  Created by Brian Baumhover on 3/23/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KIOUtil : NSObject

// Serialize a mutable dictionary to JSON
+ (NSData *)serializeEventToJSON:(NSMutableDictionary *)event error:(NSError **)error;

// Enumerate an object and massage it into a format that can be converted to JSON
+ (id)handleInvalidJSONInObject:(id)value;

/**
 Fills the error object with the given message appropriately.

 @return Always return NO.
 */
+ (BOOL)handleError:(NSError **)error withErrorMessage:(NSString *)errorMessage;

+ (BOOL)handleError:(NSError **)error
    withErrorMessage:(NSString *)errorMessage
     underlyingError:(NSError *)underlyingError;

/**
 Converts an NSDate* instance into a correctly formatted ISO-8601 compatible string.
 @param date The NSData* instance to convert.
 @returns An ISO-8601 compatible string representation of the date parameter.
 */
+ (id)convertDate:(id)date;

@end

#define IF_STRING_EMPTY_RETURN(argument) \
if (nil == argument || argument.length <= 0) { \
    NSError *error; \
    [KIOUtil handleError:&error withErrorMessage:@"'" @#argument @"' must be set and not empty"]; \
    return; \
}

#define IF_STRING_EMPTY_COMPLETE(argument) \
if (nil == argument || argument.length <= 0) { \
    NSError *error; \
    [KIOUtil handleError:&error withErrorMessage:@"'" @#argument @"' must be set and not empty"]; \
    completionHandler(nil, nil, error); \
    return; \
}

#define IF_NIL_RETURN(argument) \
if (nil == argument) { \
    NSError *error; \
    [KIOUtil handleError:&error withErrorMessage:@"'" @#argument @"' must not be nil"]; \
    return; \
}

#define IF_NIL_COMPLETE(argument) \
if (nil == argument) { \
    NSError *error; \
    [KIOUtil handleError:&error withErrorMessage:@"'" @#argument @"' must not be nil"]; \
    completionHandler(nil, nil, error); \
    return; \
}
