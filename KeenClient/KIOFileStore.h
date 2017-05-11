//
//  KIOFileStore.h
//  KeenClient
//
//  Created by Brian Baumhover on 3/22/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KIOFileStore : NSObject

/**
 Migrate data from old file-based store if present
 */
+ (void)maybeMigrateDataFromFileStore:(NSString *)projectID;

/**
 Migrate data from old file-based store
 */
+ (void)importFileDataWithProjectID:(NSString *)projectID;

@end
