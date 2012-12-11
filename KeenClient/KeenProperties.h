//
//  KeenProperties.h
//  KeenClient
//
//  Created by Daniel Kador on 12/7/12.
//  Copyright (c) 2012 Keen Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface KeenProperties : NSObject

@property (nonatomic, retain) NSDate *timestamp;
@property (nonatomic, retain) CLLocation *location;

@end
