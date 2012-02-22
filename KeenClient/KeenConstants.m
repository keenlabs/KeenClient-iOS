//
//  KeenConstants.m
//  KeenClient
//
//  Created by Daniel Kador on 2/12/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenConstants.h"

NSString * const KeenServerAddress = @"http://api.keen.io";
//NSString * const KeenServerAddress = @"http://localhost:8888";
NSString * const KeenApiVersion = @"1.0";

// Keen API constants

NSString * const KeenNameParam = @"name";
NSString * const KeenDescriptionParam = @"description";
NSString * const KeenSuccessParam = @"success";
NSString * const KeenErrorParam = @"error";
NSString * const KeenErrorCodeParam = @"error_code";
NSString * const KeenInvalidCollectionNameError = @"InvalidCollectionNameError";
NSString * const KeenInvalidPropertyNameError = @"InvalidPropertyNameError";
NSString * const KeenInvalidPropertyValueError = @"InvalidPropertyValueError";

// Keen constants related to how much data we'll cache on the device before aging it out

// how many events can be stored for a single collection before aging them out
NSUInteger const KeenMaxEventsPerCollection = 10000;
// how many events to drop when aging out
NSUInteger const KeenNumberEventsToForget = 100;