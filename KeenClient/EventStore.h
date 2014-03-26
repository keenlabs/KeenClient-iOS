//
//  EventStore.h
//  KeenClient
//
//  Created by Cory Watson on 3/26/14.
//  Copyright (c) 2014 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface EventStore : NSObject

-(BOOL)addEvent: (NSString *)eventData;

@end
