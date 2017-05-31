//
//  KIODefaultNSURLSessionFactory.m
//  KeenClient
//
//  Created by Brian Baumhover on 5/30/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

#import "KIODefaultNSURLSessionFactory.h"

@implementation KIODefaultNSURLSessionFactory

- (NSURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration {
    return [NSURLSession sessionWithConfiguration:configuration];
}

- (NSURLSession *)session {
    return [NSURLSession sharedSession];
}

@end
