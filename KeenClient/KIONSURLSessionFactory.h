//
//  KIONSURLSessionFactory.h
//  KeenClient
//
//  Created by Brian Baumhover on 5/30/17.
//  Copyright © 2017 Keen Labs. All rights reserved.
//

@protocol KIONSURLSessionFactory <NSObject>

- (NSURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration;

- (NSURLSession *)session;

@end
