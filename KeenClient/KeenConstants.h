//
//  KeenConstants.h
//  KeenClient
//
//  Created by Daniel Kador on 2/12/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kKeenSdkVersion @"3.7.0"

// Keen API constants

extern NSString *const kKeenApiUrlScheme;
extern NSString *const kKeenDefaultApiUrlAuthority;
extern NSString *const kKeenApiVersion;

extern NSString *const kKeenResponseErrorNameKey;
extern NSString *const kKeenResponseErrorDescriptionKey;
extern NSString *const kKeenSuccessParam;
extern NSString *const kKeenResponseErrorDictionaryKey;
extern NSString *const kKeenErrorCodeParam;
extern NSString *const kKeenInvalidCollectionNameError;
extern NSString *const kKeenInvalidPropertyNameError;
extern NSString *const kKeenInvalidPropertyValueError;

// The key on an event dictionary for keen-provided data
extern NSString *const kKeenEventKeenDataKey;

// A key containing the number of upload attempts for a given event
extern NSString *const kKeenEventKeenDataAttemptsKey;

// how many events can be stored for a single collection before aging them out
extern NSUInteger const kKeenMaxEventsPerCollection;

// how many events to drop when aging out
extern NSUInteger const kKeenNumberEventsToForget;

// custom domain for NSErrors
extern NSString *const kKeenErrorDomain;

// Error codes for NSError
// clang-format off
typedef NS_ENUM(NSInteger, KeenErrorCode) {
    KeenErrorCodeGeneral = 1,
    KeenErrorCodeNetworkDisconnected = 2,
    KeenErrorCodeSerialization = 3,
    KeenErrorCodeResponseError = 4,
    KeenErrorCodeEventUploadError = 6
};
// clang-format on

// Key in NSError userInfo used for storing an instance of an NSError returned
// from an underlying API call
extern NSString *const kKeenErrorInnerErrorKey;

// Key in NSError userInfo used for storing an NSArray of underlying NSErrors
extern NSString *const kKeenErrorInnerErrorArrayKey;

// Key in NSError userInfo used for error descriptions
extern NSString *const kKeenErrorDescriptionKey;

// Key in NSError userInfo used for http status codes
extern NSString *const kKeenErrorHttpStatus;

// Name of header that provides SDK version info
extern NSString *const kKeenSdkVersionHeader;

// The SDK version info header content.
extern NSString *const kKeenSdkVersionWithPlatform;

// User settings key indicating that a file store import has already been done.
extern NSString *const kKeenFileStoreImportedKey;
