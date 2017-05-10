//
//  KeenTestUtils.h
//  KeenClient
//
//  Created by Brian Baumhover on 4/27/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeenTestUtils : NSObject

+ (NSString *)cacheDirectory;
+ (NSString *)keenDirectory;
+ (NSString *)eventDirectoryForCollection:(NSString *)collection;
+ (NSArray *)contentsOfDirectoryForCollection:(NSString *)collection;
+ (NSString *)pathForEventInCollection:(NSString *)collection WithTimestamp:(NSDate *)timestamp;
+ (BOOL)writeNSData:(NSData *)data toFile:(NSString *)file;

@end
