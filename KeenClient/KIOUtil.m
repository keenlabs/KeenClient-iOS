//
//  KIOUtil.m
//  KeenClient
//
//  Created by Brian Baumhover on 3/23/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenClient.h"
#import "KeenConstants.h"
#import "KeenProperties.h"
#import "KIOUtil.h"

@implementation KIOUtil

+ (NSData *)serializeEventToJSON:(NSMutableDictionary *)event error:(NSError **)error {
    id fixed = [self handleInvalidJSONInObject:event];

    if (![NSJSONSerialization isValidJSONObject:fixed]) {
        [self handleError:error withErrorMessage:@"Event contains an invalid JSON type!"];
        return nil;
    }
    return [NSJSONSerialization dataWithJSONObject:fixed options:0 error:error];
}

+ (NSMutableDictionary *)makeDictionaryMutable:(NSDictionary *)dict {
    return [dict mutableCopy];
}

+ (NSMutableArray *)makeArrayMutable:(NSArray *)array {
    return [array mutableCopy];
}

+ (id)handleInvalidJSONInObject:(id)value {
    if (!value) {
        return value;
    }

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mutDict = [self makeDictionaryMutable:value];
        NSArray *keys = [mutDict allKeys];
        for (NSString *dictKey in keys) {
            id newValue = [self handleInvalidJSONInObject:[mutDict objectForKey:dictKey]];
            [mutDict setObject:newValue forKey:dictKey];
        }
        return mutDict;
    } else if ([value isKindOfClass:[NSArray class]]) {
        // make sure the array is mutable and then recurse for every element
        NSMutableArray *mutArr = [self makeArrayMutable:value];
        for (NSUInteger i = 0; i < [mutArr count]; i++) {
            id arrVal = [mutArr objectAtIndex:i];
            arrVal = [self handleInvalidJSONInObject:arrVal];
            [mutArr setObject:arrVal atIndexedSubscript:i];
        }
        return mutArr;
    } else if ([value isKindOfClass:[NSDate class]]) {
        return [self convertDate:value];
    } else if ([value isKindOfClass:[KeenProperties class]]) {
        KeenProperties *keenProperties = value;

        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        NSString *isoDate = [self convertDate:keenProperties.timestamp];
        if (isoDate != nil) {
            [dict setObject:isoDate forKey:@"timestamp"];
        }

        CLLocation *location = keenProperties.location;
        if (location != nil) {
            NSNumber *longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
            NSNumber *latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
            NSArray *coordinatesArray = [NSArray arrayWithObjects:longitude, latitude, nil];
            NSDictionary *coordinatesDict = [NSDictionary dictionaryWithObject:coordinatesArray forKey:@"coordinates"];
            [dict setObject:coordinatesDict forKey:@"location"];
        }

        return dict;
    } else {
        return value;
    }
}

+ (BOOL)handleError:(NSError **)error withErrorMessage:(NSString *)errorMessage {
    return [self handleError:error withErrorMessage:errorMessage underlyingError:nil];
}

+ (BOOL)handleError:(NSError **)error
    withErrorMessage:(NSString *)errorMessage
     underlyingError:(NSError *)underlyingError {
    if (error != NULL) {
        const id<NSCopying> keys[] = {NSLocalizedDescriptionKey, NSUnderlyingErrorKey};
        const id objects[] = {errorMessage, underlyingError};
        NSUInteger count = underlyingError ? 2 : 1;
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys count:count];
        *error = [NSError errorWithDomain:kKeenErrorDomain code:1 userInfo:userInfo];
        KCLogError(@"%@", *error);
    }

    return NO;
}

#pragma mark - NSDate => NSString

+ (id)convertDate:(id)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

    NSString *iso8601String = [dateFormatter stringFromDate:date];
    return iso8601String;
}

+ (BOOL)validateProjectID:(NSString *)projectID {
    // validate that project ID is acceptable
    if (!projectID || [projectID length] == 0) {
        return NO;
    }
    return YES;
}

+ (BOOL)validateKey:(NSString *)key {
    // for now just use the same rules as project ID
    return [self validateProjectID:key];
}

@end
