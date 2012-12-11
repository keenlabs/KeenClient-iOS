//
//  KeenProperties.m
//  KeenClient
//
//  Created by Daniel Kador on 12/7/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import "KeenProperties.h"

@implementation KeenProperties

@synthesize timestamp=_timestamp;
@synthesize location=_location;

- (id)init {
    self = [super init];
    
    self.timestamp = [NSDate date];
    
    return self;
}

- (void)dealloc {
    // nil out the properties which we've retained (which will release them)
    self.timestamp = nil;
    self.location = nil;
    [super dealloc];
}

@end
