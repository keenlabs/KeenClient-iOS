//
//  KeenConstants.m
//  KeenClient
//
//  Created by Daniel Kador on 2/12/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenConstants.h"

NSString *const kKeenApiUrlScheme = @"https";
NSString *const kKeenDefaultApiUrlAuthority = @"api.keen.io";
NSString *const kKeenApiVersion = @"3.0";

NSString *const kKeenResponseErrorNameKey = @"name";
NSString *const kKeenResponseErrorDescriptionKey = @"description";
NSString *const kKeenSuccessParam = @"success";
NSString *const kKeenResponseErrorDictionaryKey = @"error";
NSString *const kKeenErrorCodeParam = @"error_code";
NSString *const kKeenInvalidCollectionNameError = @"InvalidCollectionNameError";
NSString *const kKeenInvalidPropertyNameError = @"InvalidPropertyNameError";
NSString *const kKeenInvalidPropertyValueError = @"InvalidPropertyValueError";

NSString *const kKeenEventKeenDataKey = @"keen";

NSString *const kKeenEventKeenDataAttemptsKey = @"prior_attempts";

NSUInteger const kKeenMaxEventsPerCollection = 10000;

NSUInteger const kKeenNumberEventsToForget = 100;

NSString *const kKeenErrorDomain = @"io.keen";

NSString *const kKeenErrorInnerErrorKey = @"InnerError";

NSString *const kKeenErrorInnerErrorArrayKey = @"InnerErrorArray";

NSString *const kKeenErrorDescriptionKey = @"Description";

NSString *const kKeenErrorHttpStatus = @"HTTPStatus";

NSString *const kKeenSdkVersionHeader = @"Keen-Sdk";

NSString *const kKeenSdkVersionWithPlatform = @"ios-" kKeenSdkVersion;

NSString *const kKeenFileStoreImportedKey = @"didFSImport";
