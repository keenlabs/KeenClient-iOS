//
//  KIOMockNSURLSessionFactory.h
//  KeenClient
//
//  Created by Brian Baumhover on 5/31/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KIONSURLSessionFactory.h"

@interface KIOMockNSURLSessionFactory : NSObject<KIONSURLSessionFactory>

- (instancetype)initWithSession:(NSURLSession*)session;

@end
