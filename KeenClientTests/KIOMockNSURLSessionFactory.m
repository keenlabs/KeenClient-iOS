//
//  KIOMockNSURLSessionFactory.m
//  KeenClient
//
//  Created by Brian Baumhover on 5/31/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KIOMockNSURLSessionFactory.h"

@interface KIOMockNSURLSessionFactory()

// This property implements the KIONSURLSessionFactory session selector
@property NSURLSession* session;

@end

@implementation KIOMockNSURLSessionFactory

- (instancetype)initWithSession:(NSURLSession*)session {
    self = [super init];
    
    if (nil != self) {
        self.session = session;
    }
    
    return self;
}

- (NSURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration {
    return self.session;
}

@end
