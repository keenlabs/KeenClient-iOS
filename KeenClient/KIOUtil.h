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

// Enumerate a dictionary and replace immutable objects with mutable copies
+ (NSMutableDictionary *)makeDictionaryMutable:(NSDictionary *)dict;

// Create a mutable copy of an array
+ (NSMutableArray *)makeArrayMutable:(NSArray *)array;

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

// Validate a project id
+ (BOOL)validateProjectID:(NSString *)projectID;

// Validate an access key
+ (BOOL)validateKey:(NSString *)key;

@end
