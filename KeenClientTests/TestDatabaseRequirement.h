//
//  TestDatabaseRequirement.h
//  KeenClient
//
//  Created by Brian Baumhover on 5/8/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KeenTestCaseBase.h"

@interface TestDatabaseRequirement : NSObject

- (instancetype)initWithDatabasePath:(NSString *)path;

- (void)unlock;

@end
