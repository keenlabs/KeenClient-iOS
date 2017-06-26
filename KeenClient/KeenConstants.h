//
//  KeenConstants.h
//  KeenClient
//
//  Created by Daniel Kador on 2/12/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kKeenSdkVersion @"3.7.0"

extern NSString * const kKeenApiUrlScheme;
extern NSString * const kKeenDefaultApiUrlAuthority;
extern NSString * const kKeenApiVersion;

extern NSString * const kKeenNameParam;
extern NSString * const kKeenDescriptionParam;
extern NSString * const kKeenSuccessParam;
extern NSString * const kKeenErrorParam;
extern NSString * const kKeenErrorCodeParam;
extern NSString * const kKeenInvalidCollectionNameError;
extern NSString * const kKeenInvalidPropertyNameError;
extern NSString * const kKeenInvalidPropertyValueError;

extern NSUInteger const kKeenMaxEventsPerCollection;
extern NSUInteger const kKeenNumberEventsToForget;

extern NSString * const kKeenErrorDomain;

extern NSString * const kKeenSdkVersionHeader;
extern NSString * const kKeenSdkVersionWithPlatform;

extern NSString * const kKeenFileStoreImportedKey;
